{ pkgs }:

let
  dependency = pkgs.runCommand "bundle-oci-dependency" { } ''
    mkdir -p "$out"
    printf 'dependency\n' > "$out/data"
    ln "$out/data" "$out/hardlink"
  '';
  module = pkgs.runCommand "bundle-oci-module" { } ''
    mkdir -p "$out/bin"
    printf '%s\n' '${dependency}' > "$out/module.json"
    printf '#!/bin/sh\nexit 0\n' > "$out/bin/tool"
    chmod 755 "$out/bin/tool"
    ln -s ../module.json "$out/bin/relative"
    ln -s '${dependency}/data' "$out/absolute"
  '';
  bundle = (pkgs.callPackage ../bundle {
    self = { modules.fixture = module; };
  }) { };
  image = pkgs.callPackage ./. {
    inherit bundle;
    revision = "0123456789abcdef0123456789abcdef01234567";
    sourceTimestamp = 1700000000;
  };
  closure = pkgs.closureInfo { rootPaths = [ bundle ]; };
in
pkgs.runCommand "bundle-oci-check"
{
  nativeBuildInputs = [ pkgs.erofs-utils pkgs.python3 ];
}
  ''
    python3 ${./check.py} ${image} ${bundle} ${closure}/store-paths ${dependency} ${./layout.py}
    ${image.copyTo}/bin/copy-nixmodules-bundle-oci "oci:$PWD/copied:bundle" \
      --authfile ${pkgs.writeText "empty-auth.json" ''{"auths":{}}''} \
      --digestfile "$PWD/copied.digest"
    python3 - ${image} "$PWD/copied" "$PWD/copied.digest" <<'PY'
    import json, pathlib, sys
    original, copied, digest_file = map(pathlib.Path, sys.argv[1:])
    descriptor = json.loads((original / "index.json").read_text())["manifests"][0]
    copied_descriptor = json.loads((copied / "index.json").read_text())["manifests"][0]
    assert copied_descriptor["digest"] == descriptor["digest"]
    assert digest_file.read_text().strip() == descriptor["digest"]
    for blob in (original / "blobs/sha256").iterdir():
        assert blob.read_bytes() == (copied / "blobs/sha256" / blob.name).read_bytes()
    print("copyTo preserved manifest digest and every OCI blob")
    PY
    touch "$out"
  ''
