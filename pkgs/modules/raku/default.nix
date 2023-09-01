{ pkgs, lib, ... }:

let
  raku = pkgs.rakudo;

  version = lib.versions.majorMinor raku.version;
  extensions = [ ".p6" ".raku" ];
in

{
  id = "raku-${version}";
  name = "Raku Tools";

  packages = [
    raku
    pkgs.moarvm
    pkgs.nqp
    pkgs.zef
  ];

  replit.runners.raku = {
    name = "Raku";
    language = "raku";
    inherit extensions;
    fileParam = true;
    start = "${raku}/bin/raku $file";
  };
}
