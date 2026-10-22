{ pkgs, lib, bundle-image, revstring, coreutils, gnutar, pigz }:
let
  tools = [ coreutils gnutar pigz ];
in
pkgs.callPackage ../image-script.nix { } {
  name = "build-nixmodules-image-tarball";
  runtimeInputs = tools;
  builder = ./builder.sh;
  env = {
    PATH = lib.makeBinPath tools;
    imageBuilder = lib.getExe bundle-image;
  };
}
