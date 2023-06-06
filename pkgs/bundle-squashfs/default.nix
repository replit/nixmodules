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
}:

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
    inherit upgrade-maps;
    inherit active-modules;
    diskClosureInfo = closureInfo { rootPaths = [ bundle-locked registry ]; };
  };
}
