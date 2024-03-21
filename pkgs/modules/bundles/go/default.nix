{ lib, config, pkgs, ... }:
let
  cfg = config.bundles.go;
in
with pkgs.lib; {
  options = {
    bundles.go.enable = mkModuleEnableOption {
      name = "Go tools bundle";
      description = "Development tools for the Go programming language";
    };
  };

  config = mkIf cfg.enable {
    compilers.go.enable = mkDefault true;
    languageServers.gopls.enable = mkDefault true;
    formatters.gofmt.enable = mkDefault true;
  };
}
