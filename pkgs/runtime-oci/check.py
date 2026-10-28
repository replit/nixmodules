import base64
import hashlib
import importlib.util
import json
import pathlib
import struct
import subprocess
import sys

image, manifest_file, registration, runtime, ide, deployment, script, lock = map(
    pathlib.Path, sys.argv[1:]
)
manifest = json.loads(manifest_file.read_text())
assert manifest["schemaVersion"] == 1
assert manifest["kind"] == "nixmodules-runtime"
assert manifest["system"] == "x86_64-linux"
assert manifest["flakeOutput"] == "node-python-runtime-oci"
assert manifest["moduleIds"] == ["nodejs-24", "python-base-3.13"]
assert manifest["source"] == {
    "url": "https://github.com/replit/nixmodules",
    "rev": "0123456789abcdef0123456789abcdef01234567",
    "narHash": "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
    "lockFileSha256": hashlib.sha256(lock.read_bytes()).hexdigest(),
}
assert [m["id"] for m in manifest["modules"]] == manifest["moduleIds"]
roots = {m[key] for m in manifest["modules"] for key in ("developmentPath", "deploymentPath")}
assert len(roots) == 4
closure = manifest["closure"]
paths = {entry["path"] for entry in closure}
assert len(paths) == len(closure)
assert roots | {str(runtime), str(ide), str(deployment)} <= paths
assert [entry["path"] for entry in closure] == sorted(paths)
canonical = json.dumps(closure, sort_keys=True, separators=(",", ":")).encode("utf-8")
assert manifest["closureHash"] == "sha256:" + hashlib.sha256(canonical).hexdigest()
for entry in closure:
    assert entry["references"] == sorted(entry["references"])
    assert set(entry["references"]) <= paths
    assert len(base64.b64decode(entry["narHash"].removeprefix("sha256-"), validate=True)) == 32
    assert entry["narSize"] > 0


def nar_string(value):
    return struct.pack("<Q", len(value)) + value + b"\x00" * (-len(value) % 8)


for entry in closure:
    path = pathlib.Path(entry["path"])
    assert path.is_file() and not path.is_symlink()
    nar = b"".join(nar_string(part) for part in (
        b"nix-archive-1", b"(", b"type", b"regular", b"contents", path.read_bytes(), b")"
    ))
    assert entry["narSize"] == len(nar)
    assert entry["narHash"] == "sha256-" + base64.b64encode(hashlib.sha256(nar).digest()).decode("ascii")

spec = importlib.util.spec_from_file_location("runtime_manifest", script)
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)
assert generator.sri_hash("sha256:" + "0" * 52) == "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
assert generator.sri_hash("sha256:" + "0" * 51 + "1") == "sha256-AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
for invalid in ("sha512:" + "0" * 52, "sha256:short", "sha256:" + "z" * 52):
    try:
        generator.sri_hash(invalid)
    except (ValueError, OverflowError):
        pass
    else:
        raise AssertionError("accepted invalid NAR hash")

lines = iter(registration.read_text().splitlines())
registered = {}
for path in lines:
    nar_hash, nar_size, deriver, count = next(lines), next(lines), next(lines), int(next(lines))
    registered[path] = {
        "path": path,
        "narHash": generator.sri_hash(nar_hash),
        "narSize": int(nar_size),
        "references": sorted(next(lines) for _ in range(count)),
    }
assert closure == sorted(registered.values(), key=lambda entry: entry["path"])
graph = []
alphabet = "0123456789abcdfghijklmnpqrsvwxyz"
for entry in reversed(closure):
    raw_hash = base64.b64decode(entry["narHash"].removeprefix("sha256-"))
    number = int.from_bytes(raw_hash, "little")
    nix_hash = "".join(alphabet[(number >> shift) & 31] for shift in range(255, -1, -5))
    graph.append({**entry, "narHash": "sha256:" + nix_hash, "references": list(reversed(entry["references"]))})
repeated = pathlib.Path("repeated-manifest.json")
generator.write_manifest({
    "metadata": {k: v for k, v in manifest.items() if k not in ("closure", "closureHash")},
    "closure": graph,
}, repeated)
assert repeated.read_bytes() == manifest_file.read_bytes()

index = json.loads((image / "index.json").read_text())
descriptor = index["manifests"][0]
assert descriptor["annotations"]["org.opencontainers.image.ref.name"] == "bundle"


def blob(descriptor):
    path = image / "blobs/sha256" / descriptor["digest"].split(":")[1]
    assert descriptor["digest"] == "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest()
    assert descriptor["size"] == path.stat().st_size
    return path


oci = json.loads(blob(descriptor).read_text())
assert oci["annotations"]["dev.replit.nixmodules.flake-output"] == manifest["flakeOutput"]
assert oci["annotations"]["org.opencontainers.image.revision"] == manifest["source"]["rev"]
assert len(oci["layers"]) == 1
assert oci["layers"][0]["mediaType"] == "application/vnd.oci.image.layer.v1.tar+gzip"
assert json.loads(blob(oci["config"]).read_text())["config"] == {}
root = pathlib.Path("extracted")
root.mkdir()
subprocess.run([
    "tar", "-xzf", str(blob(oci["layers"][0])), "-C", str(root), "--no-same-owner"
], check=True)
for path in paths:
    assert (root / path.lstrip("/")).read_bytes() == pathlib.Path(path).read_bytes()
for module in manifest["modules"]:
    assert json.loads((root / module["developmentPath"].lstrip("/")).read_text())["id"] == module["id"]
    assert json.loads((root / module["deploymentPath"].lstrip("/")).read_text())["id"] == module["id"]


def metadata(name):
    path = root / "etc/nixmodules" / name
    target = path.readlink()
    # Resolve the absolute store symlink inside the unpacked image, not the builder store.
    while True:
        resolved = root / str(target).lstrip("/")
        if not resolved.is_symlink():
            return resolved.read_bytes()
        target = resolved.readlink()


assert metadata("runtime-manifest.json") == manifest_file.read_bytes()
for name, key in (("modules.json", "developmentPath"), ("deployment-modules.json", "deploymentPath")):
    assert json.loads(metadata(name)) == {m["id"]: {"path": m[key]} for m in manifest["modules"]}
print("Four roots, complete runtime NAR graph, source identity, OCI metadata and raw payload verified")
