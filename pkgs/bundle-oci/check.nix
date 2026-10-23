{ pkgs, ztoc-rs }:

let
  dependency = pkgs.runCommand "bundle-oci-dependency" { } ''
    mkdir -p "$out"
    printf 'dependency\n' > "$out/data"
    head -c 131072 /dev/zero >> "$out/data"
    ln "$out/data" "$out/hardlink"
  '';
  module = pkgs.runCommand "bundle-oci-module" { } ''
    mkdir -p "$out/bin"
    printf '%s\n' '${dependency}' > "$out/module.json"
    printf '#!/bin/sh\nexit 0\n' > "$out/bin/tool"
    head -c 131072 /dev/zero >> "$out/bin/tool"
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
  disk = pkgs.callPackage ../bundle-image {
    inherit bundle;
    revstring = "fixture";
    diskName = "disk.raw";
  };
  tarball = pkgs.callPackage ../bundle-image-tarball {
    bundle-image = disk;
    revstring = "fixture";
  };
  moduleImage = pkgs.callPackage ../mk-phony-oci { inherit ztoc-rs; } {
    inherit module;
    moduleId = "fixture";
  };
  failingBuilder = pkgs.callPackage ../image-script.nix { } {
    name = "failing-image";
    runtimeInputs = [ ];
    env = { };
    builder = pkgs.writeText "fail-image.sh" "exit 1";
  };
in
pkgs.runCommand "bundle-oci-check"
{
  nativeBuildInputs = [ pkgs.gnutar pkgs.gzip pkgs.python3 ];
}
  ''
    mkdir "local images"
    cd "local images"
    ${pkgs.lib.getExe image} "$PWD/image"
    if ${pkgs.lib.getExe image} "$PWD/image"; then
      echo "Builder overwrote an existing directory" >&2
      exit 1
    fi
    if ${pkgs.lib.getExe image} /nix/store/forbidden-image; then
      echo "Builder accepted an output in the Nix store" >&2
      exit 1
    fi
    ln -s /nix/store store-link
    if ${pkgs.lib.getExe image} "$PWD/store-link/forbidden-image"; then
      echo "Builder accepted a symlink into the Nix store" >&2
      exit 1
    fi
    ${pkgs.lib.getExe disk} "$PWD/disk"
    metadata=$(readlink -f ${bundle}/etc/nixmodules/modules.json)
    ${pkgs.squashfsTools}/bin/unsquashfs -cat "$PWD/disk/disk.raw" "''${metadata#/}" > modules.json
    cmp modules.json ${bundle}/etc/nixmodules/modules.json
    ${pkgs.lib.getExe tarball} "$PWD/tarball"
    tar -tzf "$PWD/tarball/disk.raw.tar.gz" | grep -x disk.raw
    ${pkgs.lib.getExe moduleImage} "$PWD/module-image"
    python3 - "$PWD/module-image" <<'PY'
    import json, pathlib, sys
    root = pathlib.Path(sys.argv[1])
    index = json.loads((root / "index.json").read_text())
    manifest = index["manifests"][0]
    assert manifest["annotations"]["org.opencontainers.image.ref.name"] == "fixture"
    body = json.loads((root / "blobs/sha256" / manifest["digest"].split(":")[1]).read_text())
    assert len(body["layers"]) == 2
    for layer in body["layers"]:
        assert (root / "blobs/sha256" / layer["digest"].split(":")[1]).stat().st_size == layer["size"]
    PY
    if ${pkgs.lib.getExe failingBuilder} "$PWD/failed-image"; then exit 1; fi
    test ! -e "$PWD/failed-image"
    test -z "$(find . -maxdepth 1 -name '*.work.*' -print)"
    python3 ${./check.py} "$PWD/image" ${bundle} ${closure}/store-paths ${dependency} ${./layout.py} ${./layer.sh}
    ${image.copyTo}/bin/copy-nixmodules-bundle-oci "$PWD/image" "oci:$PWD/copied:bundle" \
      --authfile ${pkgs.writeText "empty-auth.json" ''{"auths":{}}''} \
      --digestfile "$PWD/copied.digest"
    python3 - "$PWD/image" "$PWD/copied" "$PWD/copied.digest" <<'PY'
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
