{ lib, config, pkgs, ... }:
let
  goversion = lib.versions.majorMinor go.version;
  cfg = config.go;
  go = pkgs.go;
  gopls = pkgs.gopls;
in
with lib; {
  options = {
    go.enabled = mkOption {
      type = types.bool;
      default = false;
    };

    go.languageServer.enabled = mkOption {
      type = types.bool;
      default = false;
    };

    go.formatter.enabled = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = {
    go.languageServer.enabled = mkDefault cfg.enabled;
    go.formatter.enabled = mkDefault cfg.enabled;

    replit.packages = mkIf cfg.enabled [
      go
    ];

    replit.dev.packages = mkIf cfg.languageServer.enabled [
      gopls
    ];

    # TODO: should compile a binary to use in deployment and not include the runtime
    replit.runners.go-run = mkIf cfg.enabled {
      name = "go run";
      language = "go";

      start = "${go}/bin/go run $REPL_HOME";
    };

    replit.dev.formatters.go-fmt = mkIf cfg.formatter.enabled {
      name = "go fmt";
      language = "go";
      displayVersion = "Go ${go.version}";

      start = "${go}/bin/go fmt";
      stdin = false;
    };

    replit.dev.languageServers.gopls = mkIf cfg.languageServer.enabled {
      name = "gopls";
      language = "go";

      displayVersion = gopls.version;

      start = "${gopls}/bin/gopls";
    };
  };
}
