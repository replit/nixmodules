{ pkgs, ... }: {
  id = "nix";
  name = "Nix";
  description = ''
    Nil: Nix language server
  '';

  replit.dev.languageServers.nil = {
    name = "Nix Language Server (nil)";
    language = "nix";
    start = "${pkgs.nil}/bin/nil";
    extensions = [ ".nix" ];

    configuration.nil.formatting.command = [ "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt" ];
  };
}
