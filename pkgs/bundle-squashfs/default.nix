{self, system, bash, lib, bundle-locked, revstring, coreutils, findutils, closureInfo, squashfsTools, jq}:

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
  outputs = [ "out" ];
  env = {
    inherit label registry;
    PATH = lib.makeBinPath [
      coreutils
      findutils
      squashfsTools
      jq
    ];
    autoUpgrade = builtins.toJSON self.upgrade-maps.auto;
    recommendUpgrade = builtins.toJSON self.upgrade-maps.recommend;
    modules = builtins.toJSON self.modules;
    diskClosureInfo = closureInfo { rootPaths = [bundle-locked registry]; };
  };
}
