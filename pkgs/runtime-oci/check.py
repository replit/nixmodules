import gzip
import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tarfile

image, manifest_file, cache, closure_file, runtime, ide, deployment, assembler, lock = map(
    pathlib.Path, sys.argv[1:]
)
manifest = json.loads(manifest_file.read_bytes())
assert set(manifest) == {
    "schemaVersion", "kind", "source", "system", "flakeOutput",
    "payload", "moduleIds", "modules", "supportPolicy",
}
assert manifest["schemaVersion"] == 2
assert manifest["kind"] == "nixmodules-runtime"
assert manifest["system"] == "x86_64-linux"
assert manifest["flakeOutput"] == "node-python-runtime-oci"
assert manifest["payload"] == {"format": "native-file-cache-v1", "cachePath": "/nix-cache"}
policy = manifest["supportPolicy"]
assert manifest["moduleIds"] == policy["moduleIds"] == [
    "nodejs-22", "nodejs-24", "python-base-3.11", "python-base-3.12", "python-base-3.13",
]
assert policy == {
    "reviewedOn": "2026-10-29",
    "publishBefore": "2027-04-30",
    "moduleIds": manifest["moduleIds"],
    "missingModuleIds": ["nodejs-26", "python-base-3.14", "python-base-3.15"],
}
assert manifest["source"] == {
    "url": "https://github.com/replit/nixmodules",
    "rev": "0123456789abcdef0123456789abcdef01234567",
    "narHash": "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
    "lockFileSha256": hashlib.sha256(lock.read_bytes()).hexdigest(),
}
assert [module["id"] for module in manifest["modules"]] == manifest["moduleIds"]
roots = {
    module[key] for module in manifest["modules"]
    for key in ("developmentPath", "deploymentPath")
}
paths = set(closure_file.read_text().splitlines())
assert roots | {str(runtime), str(ide), str(deployment)} <= paths
assert len(roots) == 2 * len(manifest["moduleIds"])
assert {path.name for path in cache.glob("*.narinfo")} == {
    pathlib.Path(path).name.split("-")[0] + ".narinfo" for path in paths
}


def blob(descriptor):
    path = image / "blobs/sha256" / descriptor["digest"].split(":")[1]
    assert descriptor["digest"] == "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest()
    assert descriptor["size"] == path.stat().st_size
    return path


assert json.loads((image / "oci-layout").read_bytes()) == {"imageLayoutVersion": "1.0.0"}
index = json.loads((image / "index.json").read_bytes())
descriptor = index["manifests"][0]
assert descriptor["annotations"]["org.opencontainers.image.ref.name"] == "bundle"
oci = json.loads(blob(descriptor).read_bytes())
assert oci["annotations"] == {
    "dev.replit.nixmodules.flake-output": manifest["flakeOutput"],
    "dev.replit.nixmodules.payload-format": "native-file-cache-v1",
    "org.opencontainers.image.source": manifest["source"]["url"],
    "org.opencontainers.image.revision": manifest["source"]["rev"],
    "org.opencontainers.image.created": "2023-11-14T22:13:20Z",
}
assert len(oci["layers"]) == 1
layer = oci["layers"][0]
assert layer["mediaType"] == "application/vnd.oci.image.layer.v1.tar+gzip"
config = json.loads(blob(oci["config"]).read_bytes())
assert config["config"] == {}
assert config["architecture"] == "amd64" and config["os"] == "linux"
assert config["rootfs"] == {
    "type": "layers",
    "diff_ids": ["sha256:" + hashlib.sha256(gzip.decompress(blob(layer).read_bytes())).hexdigest()],
}
assert blob(layer).read_bytes()[3:8] == b"\x00" * 5
with tarfile.open(blob(layer), "r:gz") as archive:
    members = archive.getmembers()
    assert [member.name for member in members] == sorted(member.name for member in members)
    assert all(member.uid == member.gid == 11000 and member.mtime == 1 for member in members)
    assert all(not member.issym() and not member.islnk() for member in members)
    assert all(member.mode == (0o755 if member.isdir() else 0o444) for member in members)
    files = {member.name.removeprefix("./"): member for member in members if member.isfile()}
    expected_files = {
        "nix-cache/" + path.relative_to(cache).as_posix(): path
        for path in cache.rglob("*") if path.is_file()
    }
    expected_files["etc/nixmodules/runtime-manifest.json"] = manifest_file
    assert files.keys() == expected_files.keys()
    for name, source in expected_files.items():
        assert archive.extractfile(files[name]).read() == source.read_bytes()
    for directory in ("nar", "realisations", "debuginfo", "log"):
        assert archive.getmember("./nix-cache/" + directory).isdir()
    assert not any(member.name.startswith("./nix/") for member in members)

repeated = pathlib.Path("repeated")
subprocess.run([str(assembler), "--cache", str(cache), "--output", str(repeated)], check=True)
for path in image.rglob("*"):
    if path.is_file():
        assert path.read_bytes() == (repeated / path.relative_to(image)).read_bytes()


def rejected(arguments):
    result = subprocess.run([str(assembler), *arguments], capture_output=True)
    assert result.returncode != 0


rejected([])
rejected(["--cache", str(cache), "--output", str(image)])
rejected(["--cache", str(cache), "--output", str(cache / "nested")])
symlink = pathlib.Path("cache-link")
symlink.symlink_to(cache)
rejected(["--cache", str(symlink), "--output", "rejected-symlink"])
for name, kind in (
    ("unexpected", "file"), ("nar/symlink", "symlink"), ("nar/pipe", "fifo"),
    ("nix-cache-info", "missing"), ("nar/directory", "directory"),
):
    invalid = pathlib.Path("invalid")
    shutil.copytree(cache, invalid)
    for directory in (invalid, *(path for path in invalid.rglob("*") if path.is_dir())):
        directory.chmod(0o755)
    target = invalid / name
    if kind == "file":
        target.write_bytes(b"unexpected")
    elif kind == "symlink":
        target.symlink_to(manifest_file)
    elif kind == "fifo":
        os.mkfifo(target)
    elif kind == "missing":
        target.unlink()
    else:
        target.mkdir()
    rejected(["--cache", str(invalid), "--output", "rejected-cache"])
    assert not pathlib.Path("rejected-cache").exists()
    shutil.rmtree(invalid)
print("Native-cache fixture bytes, variable roots, support policy, OCI digests, determinism and rejection cases passed")
print("The fixture cache is unsigned; signature verification belongs to the publisher/native consumer")
