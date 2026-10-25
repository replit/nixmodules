{ pkgs, lib, bundle, revstring, coreutils, findutils, closureInfo, squashfsTools, diskName }:
let
  tools = [ coreutils findutils squashfsTools ];
in
pkgs.callPackage ../image-script.nix { } {
  name = "build-nixmodules-image";
  runtimeInputs = tools;
  builder = ./builder.sh;
  env = {
    label = "nixmodules-${revstring}";
    inherit bundle diskName;
    PATH = lib.makeBinPath tools;
    diskClosureInfo = closureInfo { rootPaths = [ bundle ]; };
  };
}
