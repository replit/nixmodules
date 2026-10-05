import hashlib
import json
import os
import pathlib
import re
import stat
import subprocess
import sys

image, bundle, closure, dependency = map(pathlib.Path, sys.argv[1:])
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
assert len(manifest["layers"]) == 1
layer = manifest["layers"][0]
assert layer["mediaType"] == "application/vnd.oci.image.layer.v1.erofs"
assert config["rootfs"] == {"type": "layers", "diff_ids": [layer["digest"]]}
erofs = blob(layer)
subprocess.run(["fsck.erofs", "--extract=extracted", str(erofs)], check=True)
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
    guest = "/" + str(target.relative_to(root))
    info = subprocess.check_output(
        ["dump.erofs", f"--path={guest}", str(erofs)], text=True
    )
    assert re.search(r"Uid:\s*11000\b", info), info
    assert re.search(r"Gid:\s*11000\b", info), info
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
