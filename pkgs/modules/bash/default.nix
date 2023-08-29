{ pkgs, ... }:

{
  id = "bash";
  name = "Bash";

  packages = [
    pkgs.bashInteractive
  ];

  replit.languageServers.bash-language-server = {
    name = "Bash Language Server";
    language = "bash";
    extensions = [ ".sh" ".bash" ];
    start = "${pkgs.nodePackages.bash-language-server}";
  };
}
