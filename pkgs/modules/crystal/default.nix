{ pkgs, lib, ... }:

let
  inherit (pkgs) crystal;

  version = lib.versions.majorMinor crystal.version;
in

{
  id = "crystal-${version}";
  name = "Crystal Tools";

  packages = [
    crystal
    pkgs.shards
  ];

  replit.runners.crystal = {
    name = "Crystal";
    language = "crystal";
    extensions = [ ".cr" ];
    fileParam = true;
    start = "crystal run $file";
  };

  # TODO: nixpkgs crystalline
}
