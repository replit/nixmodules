{ pkgs, ... }: {
  id = "nix";
  name = "Nix";
  description = ''
    Nixd: Nix language server
  '';

  replit.dev.languageServers.nixd = {
    name = "nixd";
    language = "nix";
    start = "${pkgs.nixd}/bin/nixd";
    extensions = [ ".nix" ];

    configuration = {
      options.enable = false;
    };
  };
}
