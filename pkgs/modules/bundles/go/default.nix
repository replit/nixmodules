{ lib, config, pkgs, ... }:
let
  cfg = config.bundles.go;
in
with lib; {
  options = {
    bundles.go.enable = mkEnableOption "Go tools bundle";
  };

  config = mkIf cfg.enable {
    compilers.go.enable = mkDefault true;
    languageServers.gopls.enable = mkDefault true;
  formatters.gofmt.enable = mkDefault true;
  };
}
