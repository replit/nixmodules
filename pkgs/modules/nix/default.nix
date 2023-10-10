{ pkgs, ... }: {
  id = "nix";
  name = "Nix";

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
