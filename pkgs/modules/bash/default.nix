{ pkgs, ... }:

let
  bash = pkgs.bashInteractive;

  extensions = [ ".bash" ".sh" ];
in

{
  id = "bash";
  name = "Bash";

  packages = [
    bash
  ];

  replit.runners.bash = {
    name = "Bash";
    language = "bash";
    inherit extensions;
    fileParam = true;
    start = "${bash}/bin/bash $file";
  };

  replit.languageServers.bash-language-server = {
    name = "Bash Language Server";
    language = "bash";
    inherit extensions;
    start = "${pkgs.nodePackages.bash-language-server}";
  };
}
