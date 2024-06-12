{ pkgs, ... }: {
  id = "nix";
  name = "Nix";
  description = ''
    Nil: Nix language server
  '';

  replit.dev.languageServers.nil = {
    name = "nil";
    language = "nix";
    start = "${pkgs.nil}/bin/nil";
    extensions = [ ".nix" ];

    configuration = {
      options.enable = false;
    };
  };
}
