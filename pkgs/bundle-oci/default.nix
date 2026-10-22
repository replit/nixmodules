{ pkgs
, lib
, stdenv
, bundle
, closureInfo
, coreutils
, gnutar
, gzip
, python3
, writeShellApplication
, skopeo
, revision ? null
, sourceTimestamp ? null
}:
let
  tools = [ coreutils gnutar gzip python3 pkgs.bash ];
  script = pkgs.callPackage ../image-script.nix { } {
    name = "build-nixmodules-bundle-oci";
    runtimeInputs = tools;
    builder = ./builder.sh;
    env = {
      inherit bundle;
      bundleClosure = closureInfo { rootPaths = [ bundle ]; };
      PATH = lib.makeBinPath tools;
      architecture = lib.toLower stdenv.hostPlatform.parsed.cpu.name;
      metadata = builtins.toJSON { inherit revision sourceTimestamp; };
      layerScript = ./layer.sh;
      layoutScript = ./layout.py;
    };
  };
in
script.overrideAttrs (_: {
  passthru.copyTo = writeShellApplication {
    name = "copy-nixmodules-bundle-oci";
    runtimeInputs = [ skopeo coreutils ];
    text = ''
      if [ "$#" -lt 2 ]; then
        echo "usage: copy-nixmodules-bundle-oci <local-image-directory> <transport:destination> [skopeo copy options]" >&2
        exit 2
      fi
      image=$(realpath -- "$1")
      destination="$2"
      shift 2
      exec skopeo --insecure-policy copy --preserve-digests \
        "oci:$image:bundle" "$destination" "$@"
    '';
  };
})
