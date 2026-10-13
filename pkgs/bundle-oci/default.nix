{ runCommand
, lib
, stdenv
, bundle
, modules
, hotModuleIds
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
  hotClosure = closureInfo {
    rootPaths = map
      (id: modules.${id} or (throw "bundle-oci: hot module id '${id}' is missing from modules"))
      hotModuleIds;
  };
  metadata = builtins.toJSON { inherit revision sourceTimestamp; };
  image = runCommand "nixmodules-bundle-oci"
    {
      nativeBuildInputs = [ erofs-utils python3 ];
      inherit bundle bundleClosure hotClosure;
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

      printf '0 ^etc/nixmodules/\n' > compress-hints
      metadataPath=$(readlink -f "$bundle/etc/nixmodules/modules.json")
      printf '0 ^nix/store/%.32s-\n' "''${metadataPath#/nix/store/}" >> compress-hints
      while IFS= read -r path; do
        hash="''${path#/nix/store/}"
        printf '0 ^nix/store/%.32s-\n' "$hash" >> compress-hints
      done < "$hotClosure/store-paths"

      # Hot files are uncompressed, deduplicated 4 KiB chunks, DAX-eligible
      # (Linux EROFS sets S_DAX only for FLAT_PLAIN and CHUNK_BASED).
      # Cold files use zstd and each guest's page cache, not DAX sharing.
      # Actual DAX sharing still depends on the backing storage and mount.
      mkfs.erofs -T 1 -U 00000000-0000-0000-0000-000000000000 \
        --force-uid=11000 --force-gid=11000 \
        -zzstd,level=15 -C65536 -Eztailpacking --chunksize=4096 \
        --compress-hints=compress-hints layer.erofs root
      python3 ${./layout.py} layer.erofs "$out" "$architecture" ${lib.escapeShellArg metadata}
    '';
in
image
