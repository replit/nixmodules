{ system
, bash
, lib
, bundle
, storeRegistration
, revstring
, coreutils
, findutils
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
    inherit storeRegistration;
  };
}
