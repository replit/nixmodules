{ system
, bash
, lib
, bundle-locked
, revstring
, coreutils
, findutils
, closureInfo
, squashfsTools
, jq
, upgrade-maps
, active-modules
, registry
}:

let

  label = "nixmodules-${revstring}";

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
    inherit label;
    PATH = lib.makeBinPath [
      coreutils
      findutils
      squashfsTools
      jq
    ];
    registry = builtins.toJSON registry;
    inherit upgrade-maps;
    inherit active-modules;
    diskClosureInfo = closureInfo { rootPaths = [ bundle-locked ]; };
  };
}
