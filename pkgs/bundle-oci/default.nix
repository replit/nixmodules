{ runCommand
, lib
, stdenv
, bundle
, closureInfo
, erofs-utils
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
      nativeBuildInputs = [ erofs-utils python3 ];
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
      mkdir -p root/nix/store root/etc/nixmodules "$out/blobs/sha256"
      cp -a --reflink=auto "$bundle/etc/nixmodules/." root/etc/nixmodules/
      while IFS= read -r path; do
        cp -a --reflink=auto "$path" root/nix/store/
      done < "$bundleClosure/store-paths"
      chmod 755 root root/nix root/nix/store root/etc root/etc/nixmodules

      # Match the legacy disk's guest ownership. No compression: consumers may
      # mount this blob directly; compression must not imply DAX page sharing.
      mkfs.erofs -T 1 -U 00000000-0000-0000-0000-000000000000 \
        --force-uid=11000 --force-gid=11000 layer.erofs root
      python3 ${./layout.py} layer.erofs "$out" "$architecture" ${lib.escapeShellArg metadata}
    '';
in
image
