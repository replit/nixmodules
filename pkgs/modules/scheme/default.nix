{ pkgs, replit-prompt, ... }:

let
  replbox = pkgs.callPackage ../../replbox { };

  run-replbox-name = "replbox-scheme";
  run-replbox = pkgs.writeShellScriptBin run-replbox-name ''
    ${replbox}/bin/replit-replbox --ps1 "${replit-prompt}" -i scheme $@
  '';
in

{
  id = "scheme";
  name = "Scheme Tools";

  packages = [
    run-replbox
  ];

  replit.runners.replbox-scheme = {
    name = "ReplBox Scheme";
    language = "scheme";
    optionalFileParam = true;
    start = "${run-replbox}/bin/${run-replbox-name} $file";
  };
}
