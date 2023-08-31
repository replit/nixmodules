{ pkgs, lib, ... }:

let
  inherit (pkgs) nim-unwrapped nimble-unwrapped;

  version = lib.versions.major nim-unwrapped.version;
  extensions = [ ".nim" ];
in

{
  id = "nim-${version}";
  name = "Nim Tools";

  packages = [
    nim-unwrapped
    nimble-unwrapped
    pkgs.gcc
  ];

  replit.runners.nim = {
    name = "Nim";
    language = "nim";
    inherit extensions;
    fileParam = true;
    start = "${nim-unwrapped}/bin/nim compile --run $file";
  };
}
