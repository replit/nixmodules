{ pkgs, lib, ... }:

let
  inherit (pkgs) lolcode;

  version = lib.versions.major lolcode.version;

  run-smallbar-name = "smallbar-lolcode";
  run-smallbar = pkgs.writeShellScriptBin run-smallbar-name ''
    smallbar -t "lolcode-lci -i" -r "${lolcode}/bin/lolcode-lci $@" -detect-ps1 'lci> '
  '';
in

{
  id = "lolcode-${version}";
  name = "LOLCode Tools";

  packages = [
    lolcode
  ];

  replit.runners.smallbar-lolcode = {
    name = "LOLCode in Smallbar";
    language = "lolcode";
    fileParam = true;
    interpreter = true;
    start = "${run-smallbar}/bin/${run-smallbar-name} $file";
    prompt = "lci> ";
  };
}
