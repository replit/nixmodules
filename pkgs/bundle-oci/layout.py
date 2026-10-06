import hashlib
import datetime
import json
import pathlib
import shutil
import sys


def write_layout(layer, output, architecture, metadata):
    architectures = {"x86_64": "amd64", "aarch64": "arm64"}
    architecture = architectures[architecture]
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

    def descriptor(path, media_type):
        digest = hashlib.sha256()
        with path.open("rb") as source:
            for chunk in iter(lambda: source.read(1024 * 1024), b""):
                digest.update(chunk)
        return {
            "mediaType": media_type,
            "digest": "sha256:" + digest.hexdigest(),
            "size": path.stat().st_size,
        }

    def store_json(value, media_type):
        data = json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
        path = blobs / hashlib.sha256(data).hexdigest()
        path.write_bytes(data)
        return descriptor(path, media_type)

    layer_descriptor = descriptor(layer, "application/vnd.oci.image.layer.v1.erofs")
    shutil.move(layer, blobs / layer_descriptor["digest"].split(":")[1])
    config = store_json(
        {
            **created,
            "architecture": architecture,
            "os": "linux",
            "config": {},
            "rootfs": {"type": "layers", "diff_ids": [layer_descriptor["digest"]]},
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
        pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]),
        sys.argv[3], json.loads(sys.argv[4]),
    )
