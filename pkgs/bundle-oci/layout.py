import hashlib
import datetime
import json
import pathlib
import shutil
import subprocess
import sys


def verify_layer(raw_image, compressed_layer):
    raw_image = pathlib.Path(raw_image)
    compressed_layer = pathlib.Path(compressed_layer)
    raw_digest = hashlib.sha256()
    raw_size = 0
    with raw_image.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            raw_digest.update(chunk)
            raw_size += len(chunk)

    process = subprocess.Popen(
        ["zstd", "-d", "-c", "--", str(compressed_layer)],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    decompressed_digest = hashlib.sha256()
    decompressed_size = 0
    assert process.stdout is not None
    for chunk in iter(lambda: process.stdout.read(1024 * 1024), b""):
        decompressed_digest.update(chunk)
        decompressed_size += len(chunk)
    if process.wait() != 0:
        raise ValueError("compressed EROFS layer failed zstd verification")
    if decompressed_size != raw_size or decompressed_digest.digest() != raw_digest.digest():
        raise ValueError("compressed layer does not match the raw EROFS image")


def write_layout(raw_image, compressed_layer, output, architecture, metadata):
    architectures = {"x86_64": "amd64", "aarch64": "arm64"}
    if architecture not in architectures:
        raise ValueError(f"unsupported architecture: {architecture}")
    architecture = architectures[architecture]
    raw_image = pathlib.Path(raw_image)
    compressed_layer = pathlib.Path(compressed_layer)
    output = pathlib.Path(output)
    blobs = output / "blobs" / "sha256"
    annotations = {
        "org.opencontainers.image.source": "https://github.com/replit/nixmodules",
        "dev.replit.nixmodules.flake-output": "bundle-oci",
    }
    revision = metadata["revision"]
    if revision is not None:
        if len(revision) != 40 or any(c not in "0123456789abcdef" for c in revision):
            raise ValueError("source revision must be a full lowercase Git SHA")
        annotations["org.opencontainers.image.revision"] = revision
    created = {}
    if metadata["sourceTimestamp"] is not None:
        timestamp = datetime.datetime.fromtimestamp(
            metadata["sourceTimestamp"], datetime.timezone.utc
        ).strftime("%Y-%m-%dT%H:%M:%SZ")
        annotations["org.opencontainers.image.created"] = timestamp
        created["created"] = timestamp

    raw_digest = hashlib.sha256()
    raw_size = 0
    with raw_image.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            raw_digest.update(chunk)
            raw_size += len(chunk)

    compressed_digest = hashlib.sha256()
    with compressed_layer.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            compressed_digest.update(chunk)

    def descriptor(path, media_type, digest=None):
        return {
            "mediaType": media_type,
            "digest": "sha256:" + (digest or hashlib.sha256(path.read_bytes()).hexdigest()),
            "size": path.stat().st_size,
        }

    def store_json(value, media_type):
        data = json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
        path = blobs / hashlib.sha256(data).hexdigest()
        path.write_bytes(data)
        return descriptor(path, media_type)

    layer_descriptor = {
        **descriptor(
            compressed_layer,
            "application/vnd.oci.image.layer.v1.erofs+zstd",
            compressed_digest.hexdigest(),
        ),
        "annotations": {"dev.replit.erofs.uncompressed-size": str(raw_size)},
    }
    shutil.move(compressed_layer, blobs / compressed_digest.hexdigest())
    config = store_json(
        {
            **created,
            "architecture": architecture,
            "os": "linux",
            "config": {},
            "rootfs": {"type": "layers", "diff_ids": ["sha256:" + raw_digest.hexdigest()]},
        },
        "application/vnd.oci.image.config.v1+json",
    )
    manifest = store_json(
        {
            "schemaVersion": 2,
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "config": config,
            "layers": [layer_descriptor],
            "annotations": annotations,
        },
        "application/vnd.oci.image.manifest.v1+json",
    )
    manifest["annotations"] = {"org.opencontainers.image.ref.name": "bundle"}
    (output / "index.json").write_text(
        json.dumps({"schemaVersion": 2, "manifests": [manifest]}) + "\n"
    )
    (output / "oci-layout").write_text('{"imageLayoutVersion":"1.0.0"}\n')


if __name__ == "__main__":
    write_layout(
        pathlib.Path(sys.argv[1]),
        pathlib.Path(sys.argv[2]),
        pathlib.Path(sys.argv[3]),
        sys.argv[4],
        json.loads(sys.argv[5]),
    )
