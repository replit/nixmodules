{ pkgs, lib, ... }:

let
  forth-name = "gforth";
  forth = pkgs.${forth-name};
  version = lib.versions.major forth.version;

  run-smallbar-name = "smallbar-forth";
  run-smallbar = pkgs.writeShellScriptBin run-smallbar-name ''
    smallbar -r "${forth}/bin/${forth-name} -- $@" -t ${forth-name} -switch ' \b'
  '';

  extensions = [ ".fth" ];
in

{
  id = "forth-${version}";
  name = "Forth Tools";

  packages = [
    forth
    run-smallbar
  ];

  replit.runners.smallbar-forth = {
    name = "Forth in Smallbar";
    language = "forth";
    inherit extensions;
    fileParam = true;
    interpreter = true;
    start = "${run-smallbar}/bin/${run-smallbar-name} $file";
  };
}
