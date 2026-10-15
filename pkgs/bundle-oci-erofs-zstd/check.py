import hashlib
import importlib.util
import json
import os
import pathlib
import re
import stat
import subprocess
import sys


image, bundle, closure, dependency, module, layout_script = map(pathlib.Path, sys.argv[1:])
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
annotations = manifest["annotations"]
assert annotations == {
    "org.opencontainers.image.source": "https://github.com/replit/nixmodules",
    "org.opencontainers.image.revision": "0123456789abcdef0123456789abcdef01234567",
    "org.opencontainers.image.created": config["created"],
    "dev.replit.nixmodules.flake-output": "bundle-oci-erofs-zstd",
}
assert len(manifest["layers"]) == 1
layer = manifest["layers"][0]
assert layer["mediaType"] == "application/vnd.oci.image.layer.v1.erofs+zstd"
assert layer["annotations"]["dev.replit.erofs.uncompressed-size"].isdecimal()
assert set(layer["annotations"]) == {"dev.replit.erofs.uncompressed-size"}
compressed = blob(layer)
assert layer["annotations"]["dev.replit.erofs.uncompressed-size"] == str(
    int(layer["annotations"]["dev.replit.erofs.uncompressed-size"])
)
raw = pathlib.Path("raw.erofs")
subprocess.run(["zstd", "-d", "-f", str(compressed), "-o", str(raw)], check=True)
raw_bytes = raw.read_bytes()
raw_digest = "sha256:" + hashlib.sha256(raw_bytes).hexdigest()
assert config["rootfs"] == {"type": "layers", "diff_ids": [raw_digest]}
assert layer["digest"] != raw_digest
assert layer["annotations"]["dev.replit.erofs.uncompressed-size"] == str(len(raw_bytes))
dump_stats = subprocess.run(
    ["dump.erofs", "-S", str(raw)], capture_output=True, text=True, check=True
).stdout
assert re.search(r"Filesystem compressed files:\s+0\b", dump_stats)
dump_superblock = subprocess.run(
    ["dump.erofs", "-s", str(raw)], capture_output=True, text=True, check=True
).stdout
assert (
    "Filesystem UUID:                              00000000-0000-0000-0000-000000000001"
    in dump_superblock
)
features = next(line for line in dump_superblock.splitlines() if "Filesystem features:" in line)
assert "compr_cfgs" not in features
tool_inode = subprocess.run(
    ["dump.erofs", f"--path={module}/bin/tool", str(raw)],
    capture_output=True,
    text=True,
    check=True,
).stdout
assert "Layout: 0" in tool_inode
assert "Uid: 11000   Gid: 11000" in tool_inode
subprocess.run(
    [
        "fsck.erofs",
        "--preserve-perms",
        "--xattrs",
        *(["--preserve-owner"] if os.geteuid() == 0 else []),
        f"--extract={pathlib.Path('extracted')}",
        str(raw),
    ],
    check=True,
)
root = pathlib.Path("extracted")
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
fixture_module = root / str(module).lstrip("/")
assert (fixture_module / "module.json").stat().st_ino == (
    fixture_module / "module-hardlink"
).stat().st_ino
assert stat.S_IMODE((fixture_module / "bin/tool").stat().st_mode) == 0o751
assert os.readlink(fixture_module / "bin/relative") == "../module.json"
assert os.readlink(fixture_module / "absolute") == f"{dependency}/data"
if os.geteuid() == 0:
    assert (fixture_module / "bin/tool").stat().st_uid == 11000
    assert (fixture_module / "bin/tool").stat().st_gid == 11000
print("EROFS payload, closure, plain layout, modes, symlinks, hardlinks and ownership verified")

layout_spec = importlib.util.spec_from_file_location("layout", layout_script)
layout = importlib.util.module_from_spec(layout_spec)
layout_spec.loader.exec_module(layout)
layout.verify_layer(raw, compressed)
metadata = {
    "revision": "0123456789abcdef0123456789abcdef01234567",
    "sourceTimestamp": 1700000000,
}


def expect_error(raw_path, compressed_path):
    try:
        layout.verify_layer(raw_path, compressed_path)
    except (OSError, ValueError, subprocess.SubprocessError):
        return
    raise AssertionError("invalid layout input was accepted")


truncated = pathlib.Path("truncated.zst")
truncated.write_bytes(compressed.read_bytes()[:-4])
expect_error(raw, truncated)
corrupt = pathlib.Path("corrupt.zst")
corrupt.write_bytes(compressed.read_bytes()[:-1] + bytes([compressed.read_bytes()[-1] ^ 0xFF]))
expect_error(raw, corrupt)
mismatch = pathlib.Path("mismatch.erofs")
mismatch.write_bytes(raw_bytes + b"mismatch")
expect_error(mismatch, compressed)
expect_error(pathlib.Path("missing.erofs"), compressed)
for architecture, invalid_metadata in (
    ("unsupported", metadata),
    ("x86_64", {"revision": "bad", "sourceTimestamp": None}),
):
    invalid_output = pathlib.Path("invalid-layout")
    (invalid_output / "blobs/sha256").mkdir(parents=True, exist_ok=True)
    try:
        layout.write_layout(raw, compressed, invalid_output, architecture, invalid_metadata)
    except ValueError:
        continue
    raise AssertionError("invalid layout metadata was accepted")

repeat = pathlib.Path("repeat.zst")
subprocess.run(
    [
        "zstd",
        "-15",
        "--long=27",
        "-T8",
        "--check",
        "--no-progress",
        "--quiet",
        str(raw),
        "-o",
        str(repeat),
    ],
    check=True,
)
assert repeat.read_bytes() == compressed.read_bytes()
repeat_layout = pathlib.Path("repeat-layout")
(repeat_layout / "blobs/sha256").mkdir(parents=True)
layout.write_layout(raw, repeat, repeat_layout, "x86_64", metadata)
for path in image.rglob("*"):
    if path.is_file():
        assert path.read_bytes() == (repeat_layout / path.relative_to(image)).read_bytes()

xattr_root = pathlib.Path("xattr-root")
xattr_root.mkdir()
xattr_file = xattr_root / "xattr-data"
xattr_file.write_bytes(b"extended attribute fixture\n")
os.setxattr(xattr_file, "user.fixture", b"preserved")
xattr_raw = pathlib.Path("xattr.erofs")
mkfs_args = [
    "mkfs.erofs",
    "-U", "00000000-0000-0000-0000-000000000001",
    "-T", "1",
    "--force-uid=11000",
    "--force-gid=11000",
    "-E", "noinline_data",
    str(xattr_raw),
    str(xattr_root),
]
subprocess.run(mkfs_args, check=True)
xattr_dump = subprocess.run(
    ["dump.erofs", f"--path=/{xattr_file.name}", str(xattr_raw)],
    capture_output=True,
    text=True,
    check=True,
).stdout
assert "Layout: 0" in xattr_dump
assert "Uid: 11000   Gid: 11000" in xattr_dump
os.utime(xattr_file, (12345, 12345))
os.utime(xattr_root, (23456, 23456))
xattr_repeat = pathlib.Path("xattr-repeat.erofs")
subprocess.run(mkfs_args[:-2] + [str(xattr_repeat), str(xattr_root)], check=True)
assert xattr_raw.read_bytes() == xattr_repeat.read_bytes()
xattr_extracted = pathlib.Path("xattr-extracted")
subprocess.run(
    [
        "fsck.erofs",
        "--preserve-perms",
        "--xattrs",
        *(["--preserve-owner"] if os.geteuid() == 0 else []),
        f"--extract={xattr_extracted}",
        str(xattr_raw),
    ],
    check=True,
)
assert os.getxattr(xattr_extracted / "xattr-data", "user.fixture") == b"preserved"
if os.geteuid() == 0:
    assert (xattr_extracted / "xattr-data").stat().st_uid == 11000
    assert (xattr_extracted / "xattr-data").stat().st_gid == 11000
print("Deterministic compression, xattrs, forced ownership and invalid-input checks verified")
