{ system
, bash
, lib
, coreutils
, closureInfo
, gnutar
, pigz
, ztoc-rs
}:

{ module, moduleId }:
let
  sanitizedModuleId = builtins.replaceStrings [ ":" ] [ "_" ] moduleId;
in
derivation {
  name = "oci-image-${sanitizedModuleId}";
  builder = "${bash}/bin/bash";
  args = [ ./builder.sh ];
  inherit system;
  __structuredAttrs = true;
  unsafeDiscardReferences.out = true;
  outputs = [ "out" ];
  env = {
    MODULE_ID = moduleId;
    PATH = lib.makeBinPath [
      coreutils
      coreutils
      gnutar
      pigz
      ztoc-rs
    ];
    diskClosureInfo = closureInfo { rootPaths = [ module ]; };
  };
}
