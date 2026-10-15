import hashlib
import gzip
import errno
import importlib.util
import json
import os
import pathlib
import stat
import shutil
import subprocess
import sys
import tarfile

image, bundle, closure, dependency, layout_script, layer_script = map(pathlib.Path, sys.argv[1:])
assert json.loads((image / "oci-layout").read_text()) == {"imageLayoutVersion": "1.0.0"}


def blob(descriptor):
    path = image / "blobs" / "sha256" / descriptor["digest"].removeprefix("sha256:")
    assert path.stat().st_size == descriptor["size"]
    assert "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest() == descriptor["digest"]
    return path


index = json.loads((image / "index.json").read_text())
assert index["schemaVersion"] == 2 and len(index["manifests"]) == 1
manifest = json.loads(blob(index["manifests"][0]).read_text())
assert manifest["schemaVersion"] == 2
assert manifest["mediaType"] == "application/vnd.oci.image.manifest.v1+json"
assert manifest["config"]["mediaType"] == "application/vnd.oci.image.config.v1+json"
config = json.loads(blob(manifest["config"]).read_text())
assert config["architecture"] == "amd64" and config["os"] == "linux"
assert config["created"] == "2023-11-14T22:13:20Z"
assert manifest["annotations"] == {
    "org.opencontainers.image.source": "https://github.com/replit/nixmodules",
    "org.opencontainers.image.revision": "0123456789abcdef0123456789abcdef01234567",
    "org.opencontainers.image.created": config["created"],
    "dev.replit.nixmodules.flake-output": "bundle-oci",
}
assert len(manifest["layers"]) == 1
layer = manifest["layers"][0]
assert layer["mediaType"] == "application/vnd.oci.image.layer.v1.tar+gzip"
archive = blob(layer)
tar_data = gzip.decompress(archive.read_bytes())
diff_id = "sha256:" + hashlib.sha256(tar_data).hexdigest()
assert config["rootfs"] == {"type": "layers", "diff_ids": [diff_id]}
assert diff_id != layer["digest"]
assert archive.read_bytes()[3:8] == b"\x00" * 5
spec = importlib.util.spec_from_file_location("layout", layout_script)
layout = importlib.util.module_from_spec(spec)
spec.loader.exec_module(layout)
repeated = pathlib.Path("repeated")
(repeated / "blobs/sha256").mkdir(parents=True)
shutil.copyfile(archive, "repeated.tar.gz")
layout.write_layout(pathlib.Path("repeated.tar.gz"), repeated, "x86_64", {
    "revision": "0123456789abcdef0123456789abcdef01234567",
    "sourceTimestamp": 1700000000,
})
for path in image.rglob("*"):
    if path.is_file():
        assert path.read_bytes() == (repeated / path.relative_to(image)).read_bytes()
local = pathlib.Path("local")
(local / "blobs/sha256").mkdir(parents=True)
shutil.copyfile(archive, "local.tar.gz")
layout.write_layout(pathlib.Path("local.tar.gz"), local, "x86_64", {
    "revision": None, "sourceTimestamp": None,
})
local_descriptor = json.loads((local / "index.json").read_text())["manifests"][0]
local_manifest = json.loads(
    (local / "blobs/sha256" / local_descriptor["digest"].split(":")[1]).read_text()
)
assert "org.opencontainers.image.revision" not in local_manifest["annotations"]
assert "org.opencontainers.image.created" not in local_manifest["annotations"]
local_config = json.loads(
    (local / "blobs/sha256" / local_manifest["config"]["digest"].split(":")[1]).read_text()
)
assert "created" not in local_config
root = pathlib.Path("extracted")
root.mkdir()
subprocess.run([
    "tar", "--extract", "--gzip", "--file", str(archive),
    "--directory", str(root), "--no-same-owner", "--same-permissions",
    "--xattrs", "--xattrs-include=*",
], check=True)
with tarfile.open(archive, "r:gz") as source:
    members = source.getmembers()
    assert all(m.uid == 11000 and m.gid == 11000 and m.mtime == 1 for m in members)
    assert all(not m.uname and not m.gname for m in members)
    assert all("atime" not in m.pax_headers and "ctime" not in m.pax_headers for m in members)
    assert [m.name for m in members] == sorted(m.name for m in members)

rebuilt = pathlib.Path("rebuilt.tar.gz")
subprocess.run(["bash", str(layer_script), str(root), str(rebuilt)], check=True)
assert rebuilt.read_bytes() == archive.read_bytes()
print("Tar metadata and reproducible gzip layer verified")

paths = closure.read_text().splitlines()
assert str(dependency) in paths
assert {p.name for p in (root / "nix/store").iterdir()} == {
    pathlib.Path(p).name for p in paths
}


def compare(source, target):
    before, after = source.lstat(), target.lstat()
    assert stat.S_IFMT(before.st_mode) == stat.S_IFMT(after.st_mode), target
    assert stat.S_IMODE(before.st_mode) == stat.S_IMODE(after.st_mode), target
    if source.is_symlink():
        assert os.readlink(source) == os.readlink(target), target
    elif source.is_dir():
        assert {p.name for p in source.iterdir()} == {p.name for p in target.iterdir()}
        for child in source.iterdir():
            compare(child, target / child.name)
    else:
        assert source.read_bytes() == target.read_bytes(), target


for path in paths:
    compare(pathlib.Path(path), root / path.lstrip("/"))
for metadata in (bundle / "etc/nixmodules").iterdir():
    compare(metadata, root / "etc/nixmodules" / metadata.name)
packed_dependency = root / str(dependency).lstrip("/")
assert (packed_dependency / "data").stat().st_ino == (
    packed_dependency / "hardlink"
).stat().st_ino
print("OCI descriptors, complete closure, metadata, content, modes, symlinks, ownership and hardlinks verified")

xattr_root = pathlib.Path("xattrs")
xattr_root.mkdir()
xattr_file = xattr_root / ("long-name-" * 20)
xattr_file.write_bytes(b"xattrs\n")
try:
    os.setxattr(xattr_file, "user.fixture", b"preserved")
    xattrs_supported = True
except OSError as error:
    if error.errno != errno.ENOTSUP:
        raise
    xattrs_supported = False
    print("Skipping xattr round-trip: build filesystem does not support xattrs")
subprocess.run(["bash", str(layer_script), str(xattr_root), "xattrs.tar.gz"], check=True)
with tarfile.open("xattrs.tar.gz", "r:gz") as source:
    member = source.getmember("./" + xattr_file.name)
    assert member.isfile() and source.extractfile(member).read() == b"xattrs\n"
    if xattrs_supported:
        assert member.pax_headers["SCHILY.xattr.user.fixture"] == "preserved"
if xattrs_supported:
    restored = pathlib.Path("xattrs-restored")
    restored.mkdir()
    subprocess.run([
        "tar", "--extract", "--gzip", "--file=xattrs.tar.gz",
        "--directory", str(restored), "--no-same-owner",
        "--xattrs", "--xattrs-include=*",
    ], check=True)
    assert os.getxattr(restored / xattr_file.name, "user.fixture") == b"preserved"
    print("Extended attributes preserved in archive and extraction")
os.utime(xattr_file, (12345, 67890))
subprocess.run(["bash", str(layer_script), str(xattr_root), "xattrs-again.tar.gz"], check=True)
assert pathlib.Path("xattrs.tar.gz").read_bytes() == pathlib.Path("xattrs-again.tar.gz").read_bytes()
print("Long paths preserved; source timestamps do not change the layer")
