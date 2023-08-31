{ pkgs, replit-prompt, ... }:

let
  replbox = pkgs.callPackage ../../replbox { };

  run-replbox-name = "replbox-roy";
  run-replbox = pkgs.writeShellScriptBin run-replbox-name ''
    ${replbox}/bin/replit-replbox --ps1 "${replit-prompt}" -i roy $@
  '';
in

{
  id = "roy";
  name = "Roy Tools";

  replit.runners.replbox-roy = {
    name = "ReplBox Roy";
    language = "roy";
    optionalFileParam = true;
    start = "${run-replbox}/bin/${run-replbox-name} $file";
  };
}
