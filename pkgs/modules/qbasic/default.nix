{ pkgs, ... }:

let
  replbox = pkgs.callPackage ../../replbox { };

  run-replbox-name = "replbox-qbasic";
  run-replbox = pkgs.writeShellScriptBin run-replbox-name ''
    ${replbox}/bin/replit-replbox \
      --ps1 "''$(printf '\u0001\u001b[33m\u0002\u0001\u001b[00m\u0002 ')" \
      -i qbasic ''$1
  '';
in

{
  id = "qbasic";
  name = "QBASIC Tools (with Replbox)";

  replit.runners.replbox-qbasic = {
    name = "ReplBox QBASIC";
    language = "basic";

    start = "${run-replbox}/bin/${run-replbox-name} $file";
    interpreter = true;
    fileParam = true;
  };
}
