import base64
import hashlib
import json
import pathlib
import sys


def sri_hash(value):
    if not value.startswith("sha256:"):
        raise ValueError("expected a Nix SHA256 NAR hash")
    encoded = value.removeprefix("sha256:")
    alphabet = "0123456789abcdfghijklmnpqrsvwxyz"
    if len(encoded) != 52 or any(c not in alphabet for c in encoded):
        raise ValueError("invalid Nix base32 SHA256 hash")
    number = sum(alphabet.index(c) << (5 * i) for i, c in enumerate(reversed(encoded)))
    return "sha256-" + base64.b64encode(number.to_bytes(32, "little")).decode("ascii")


def write_manifest(attributes, output):
    closure = sorted(
        [
            {
                "path": entry["path"],
                "narHash": sri_hash(entry["narHash"]),
                "narSize": entry["narSize"],
                "references": sorted(entry["references"]),
            }
            for entry in attributes["closure"]
        ],
        key=lambda entry: entry["path"],
    )
    data = json.dumps(closure, sort_keys=True, separators=(",", ":")).encode("utf-8")
    manifest = {
        **attributes["metadata"],
        "closure": closure,
        "closureHash": "sha256:" + hashlib.sha256(data).hexdigest(),
    }
    output.write_text(json.dumps(manifest, sort_keys=True, separators=(",", ":")) + "\n")


if __name__ == "__main__":
    write_manifest(json.loads(pathlib.Path(sys.argv[1]).read_text()), pathlib.Path(sys.argv[2]))
