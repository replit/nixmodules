{ pkgs, replit-prompt, ... }:

let
  replbox = pkgs.callPackage ../../replbox { };
  
  run-replbox = pkgs.writeShellScriptBin "replbox-emoticon" ''
    ${replbox}/bin/replit-replbox \
      --ps1 "${replit-prompt}" \
      -i emoticon \
      $@
  '';
in

{
  id = "emoticon";
  name = "Emoticon Tools";

  replit.runners.replbox-emoticon = {
    name = "ReplBox Emoticon";
    language = "emoticon";
    interpreter = true;
    fileParam = true;
    start = "${run-replbox}/bin/replbox-emoticon $file";
  };
}
