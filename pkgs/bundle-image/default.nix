{ system
, bash
, lib
, bundle-locked
, lkl
, coreutils
, findutils
, e2fsprogs
, closureInfo
, jq
, upgrade-maps
, active-modules
, flake
}:

let
  label = "nixmodules-${flake.revstring}";

  registry = ../../modules.json;
in

derivation {
  name = label;
  builder = "${bash}/bin/bash";
  args = [ ./builder.sh ];
  inherit system;
  __structuredAttrs = true;
  unsafeDiscardReferences.out = true;
  env = {
    inherit label registry;
    PATH = lib.makeBinPath [
      coreutils
      findutils
      lkl
      e2fsprogs
      jq
    ];
    inherit upgrade-maps;
    inherit active-modules;
    blockSize = toString (4 * 1024); # ext4fs block size (not block device sector size)
    diskClosureInfo = closureInfo { rootPaths = [ bundle-locked registry ]; };
  };
}
