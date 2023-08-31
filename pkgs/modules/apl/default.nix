{ pkgs, lib, ... }:

let
  apl = pkgs.gnuapl;

  community-version = lib.versions.majorMinor apl.version;
in

{
  id = "apl-${community-version}";
  name = "APL";

  packages = [
    apl
  ];

  replit.runners.apl = {
    name = "apl";
    language = "APL";
    extensions = [ ".apl" ];

    start = "${apl}/bin/apl -q --OFF --noCIN -f $file";
    fileParam = true;
  };
}
