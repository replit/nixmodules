{ system
, bash
, lib
, bundle-locked
, revstring
, coreutils
, findutils
, e2fsprogs
, closureInfo
, jq
, upgrade-maps
, active-modules
, squashfsTools
, fetchFromGitHub
, pkgs
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
  env = {
    inherit label registry;
    PATH = lib.makeBinPath [
      coreutils
      findutils
      squashfsTools
    ];
    inherit upgrade-maps;
    inherit active-modules;
    diskClosureInfo = closureInfo { rootPaths = [ bundle-locked registry ]; };
  };
}
