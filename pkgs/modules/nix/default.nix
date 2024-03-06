{ pkgs, ... }: {
  id = "nix";
  name = "Nix";

  replit.dev.languageServers.nixd = {
    name = "nixd";
    language = "nix";
    displayVersion = pkgs.nixd.version;
    start = "${pkgs.nixd}/bin/nixd";
    extensions = [ ".nix" ];

    configuration = {
      options.enable = false;
    };
  };
}
