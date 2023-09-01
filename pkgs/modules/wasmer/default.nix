{ pkgs, lib, ... }:

let
  inherit (pkgs) wasmer;
  version = lib.versions.majorMinor wasmer.version;
in

{
  id = "wasmer-${version}";
  name = "wasmer Tools";

  packages = [
    wasmer
  ];

  replit.runners.wasmer = {
    name = "wasmer";
    language = "wasm";
    extensions = [ ".wasm" ".wat" ];
    fileParam = true;
    start = "${wasmer}/bin/wasmer run -i main $file";
  };
}
