{ pkgs, lib, replit-prompt, ... }:

let
  inherit (pkgs) tcl;
  version = lib.versions.majorMinor tcl.version;

  run-prybar-name = "prybar-tcl";
  run-prybar = pkgs.writeScriptBin run-prybar-name ''
    ${pkgs.prybar.prybar-tcl}/bin/prybar-tcl -q --ps1 "${replit-prompt}" -i $@
  '';
in

{
  id = "tcl-${version}";
  name = "TCL ${version} Tools";

  packages = [
    tcl
  ];

  replit.runners.tcl = {
    name = "TCL";
    language = "tcl";
    fileParam = true;
    start = "${run-prybar}/bin/${run-prybar-name} $file";
  };
}
