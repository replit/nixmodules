{ pkgs, lib, coreutils, closureInfo, gnutar, pigz, ztoc-rs }:
{ module, moduleId }:
let
  sanitizedModuleId = builtins.replaceStrings [ ":" ] [ "_" ] moduleId;
  tools = [ coreutils gnutar pigz ztoc-rs ];
in
pkgs.callPackage ../image-script.nix { } {
  name = "build-oci-image-${sanitizedModuleId}";
  runtimeInputs = tools;
  builder = ./builder.sh;
  env = {
    MODULE_ID = moduleId;
    PATH = lib.makeBinPath tools;
    diskClosureInfo = closureInfo { rootPaths = [ module ]; };
  };
}
