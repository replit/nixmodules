{ lib, config, pkgs, ... }:
let
  cfg = config.compilers.go;
  go = pkgs.go;
in with lib; {

  options = {
    compilers.go = {
      enable = mkEnableOption ''
        Go compiler
        An open-source programming language supported by Google'';

      version = mkOption {
        type = types.enum [go.version];
        default = go.version;
      };
    };
  };

  config = mkIf cfg.enable {
    replit.packages = [
      go
    ];

    replit.runners.go-run = {
      name = "go run";
      language = "go";
      displayVersion = go.version;

      start = "${go}/bin/go run $REPL_HOME";
    };
  };
}