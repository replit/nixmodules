{ pkgs, lib, ... }: {
  id = "bash";
  name = "Bash Tools";

  replit.runners.bash = {
    name = "Bash";
    language = "bash";
    start = "${pkgs.bashInteractive}/bin/bash $file";
    optionalFileParam = true;
  };

  replit.dev.languageServers.bash-language-server = {
    name = "Bash Language Server";
    language = "bash";
    extensions = [ ".sh" ".bash" ];

    start = "${pkgs.nodePackages.bash-language-server}/bin/bash-language-server start";
  };
}

