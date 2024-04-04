{ lib, config, pkgs, ... }:
let
  cfg = config.formatters.gofmt;
  go = pkgs.go;
in
with pkgs.lib; {
  options = {
    formatters.gofmt.enable = mkModuleEnableOption {
      name = "Gofmt";
      description = "Gofmt is a tool that automatically formats Go source code";
    };
  };

  config = mkIf cfg.enable {
    replit.dev.formatters.gofmt = {
      name = "go fmt";
      language = "go";
      displayVersion = "Go ${go.version}";

      start = "${go}/bin/go fmt";
      stdin = false;
    };
  };
}
