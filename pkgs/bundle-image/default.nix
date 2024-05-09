{ system
, bash
, lib
, bundle
, revstring
, coreutils
, findutils
, closureInfo
, squashfsTools
, fetchFromGitHub
, pkgs
, diskName
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
  env = {
    inherit label bundle diskName;
    PATH = lib.makeBinPath [
      coreutils
      findutils
      squashfsTools
    ];
    diskClosureInfo = closureInfo { rootPaths = [ bundle ]; };
  };
}
