{ lib, config, pkgs, ... }:
let
  goversion = lib.versions.majorMinor go.version;
  cfg = config.go;
  go = pkgs.go;
  gopls = pkgs.gopls;
in
with lib; {
  options = {
    go.enable = mkOption {
      type = types.bool;
      default = false;
    };

    go.languageServer.enable = mkOption {
      type = types.bool;
      default = false;
    };

    go.formatter.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    go.languageServer.enable = mkDefault true;
    go.formatter.enable = mkDefault true;

    replit.packages = mkIf cfg.enable [
      go
    ];

    replit.dev.packages = mkIf cfg.languageServer.enable [
      gopls
    ];

    # TODO: should compile a binary to use in deployment and not include the runtime
    replit.runners.go-run = mkIf cfg.enable {
      name = "go run";
      language = "go";

      start = "${go}/bin/go run $REPL_HOME";
    };

    replit.dev.formatters.go-fmt = mkIf cfg.formatter.enable {
      name = "go fmt";
      language = "go";
      displayVersion = "Go ${go.version}";

      start = "${go}/bin/go fmt";
      stdin = false;
    };

    replit.dev.languageServers.gopls = mkIf cfg.languageServer.enable {
      name = "gopls";
      language = "go";

      displayVersion = gopls.version;

      start = "${gopls}/bin/gopls";
    };
  };
}
