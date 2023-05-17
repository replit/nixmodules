{self, system, bash, lib, bundle-locked, revstring, lkl, coreutils, findutils, e2fsprogs, closureInfo, jq}:

let

  label = "nixmodules-${revstring}";

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
    autoUpgrade = builtins.toJSON self.upgrade-maps.auto;
    recommendUpgrade = builtins.toJSON self.upgrade-maps.recommend;
    modules = builtins.toJSON self.modules;
    blockSize = toString (4 * 1024); # ext4fs block size (not block device sector size)
    diskClosureInfo = closureInfo { rootPaths = [bundle-locked registry]; };
  };
}
