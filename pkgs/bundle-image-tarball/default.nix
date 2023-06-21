{ pkgs, bundle-image, revstring, ... }:

with pkgs;

derivation {
  name = "nixmodules-${revstring}";
  builder = "${bash}/bin/bash";
  args = [ ./builder.sh ];
  inherit system;
  __structuredAttrs = true;
  unsafeDiscardReferences.out = true;
  env = {
    PATH = lib.makeBinPath [
      coreutils
      gnutar
      pigz
    ];
    inherit bundle-image;
  };
}
