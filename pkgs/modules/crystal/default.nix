{ pkgs, lib, ... }:

let
  version = lib.versions.majorMinor pkgs.crystal.version;
in

{
  id = "crystal-${version}";
  name = "Crystal Tools";

  packages = [
    pkgs.crystal
    pkgs.shards
  ];

  replit.runners.crystal = {
    name = "Crystal";
    language = "crystal";
    extensions = [ ".cr" ];
    fileParam = true;
    start = "${pkgs.crystal}/bin/crystal run $file";
  };

  # TODO: nixpkgs crystalline
}
