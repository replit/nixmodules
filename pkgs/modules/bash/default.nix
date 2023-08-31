{ pkgs, ... }:

let
  extensions = [ ".bash" ".sh" ];
in

{
  id = "bash";
  name = "Bash";

  packages = [
    pkgs.bashInteractive
  ];

  replit.runners.bash = {
    name = "Bash";
    language = "bash";
    inherit extensions;
    fileParam = true;
    start = "bash $file";
  };

  replit.languageServers.bash-language-server = {
    name = "Bash Language Server";
    language = "bash";
    inherit extensions;
    start = "${pkgs.nodePackages.bash-language-server}";
  };
}
