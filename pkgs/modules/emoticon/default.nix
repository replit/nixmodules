{ pkgs, replit-prompt, ... }:

let
  replbox = pkgs.callPackage ../../replbox { };
  
  run-replbox-name = "replbox-emoticon";
  run-replbox = pkgs.writeShellScriptBin run-replbox-name ''
    ${replbox}/bin/replit-replbox \
      --ps1 "${replit-prompt}" \
      -i emoticon \
      $@
  '';
in

{
  id = "emoticon";
  name = "Emoticon Tools";

  packages = [
    replbox
    run-replbox
  ];

  replit.runners.replbox-emoticon = {
    name = "ReplBox Emoticon";
    language = "emoticon";
    interpreter = true;
    fileParam = true;
    start = "${run-replbox}/bin/${run-replbox-name} $file";
  };
}
