{ runCommand
, lib
, stdenv
, bundle
, closureInfo
, erofs-utils
, zstd
, python3
, writeShellApplication
, skopeo
, revision ? null
, sourceTimestamp ? null
}:

let
  bundleClosure = closureInfo { rootPaths = [ bundle ]; };
  metadata = builtins.toJSON { inherit revision sourceTimestamp; };
  image = runCommand "nixmodules-bundle-oci"
    {
      nativeBuildInputs = [ erofs-utils zstd python3 ];
      inherit bundle bundleClosure;
      architecture = lib.toLower stdenv.hostPlatform.parsed.cpu.name;
      __structuredAttrs = true;
      # The embedded closure must not retain references to the builder's store.
      unsafeDiscardReferences.out = true;
      passthru.copyTo = writeShellApplication {
        name = "copy-nixmodules-bundle-oci";
        runtimeInputs = [ skopeo ];
        text = ''
          if [ "$#" -lt 1 ]; then
            echo "usage: copy-nixmodules-bundle-oci <transport:destination> [skopeo copy options]" >&2
            exit 1
          fi
          destination="$1"
          shift
          exec skopeo --insecure-policy copy --preserve-digests \
            "oci:${image}:bundle" "$destination" "$@"
        '';
      };
    }
    ''
      bash ${./build.sh} "$bundle" "$bundleClosure/store-paths" "$out" "$architecture" ${lib.escapeShellArg metadata} ${./layout.py}
    '';
in
image
