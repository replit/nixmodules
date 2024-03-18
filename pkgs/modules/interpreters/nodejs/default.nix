{ pkgs, lib, config, ... }:
let
  cfg = config.interpreters.nodejs;
  nodejs = pkgs.${"nodejs_${cfg.version}"};
  nodepkgs = pkgs.nodePackages.override {
    inherit nodejs;
  };

  nodejs-wrapped = pkgs.lib.mkWrapper-replit_ld_library_path nodejs;

  short-version = lib.versions.major nodejs.version;

  npx-wrapper = pkgs.writeShellApplication {
    name = "npx";
    text = ''
      mkdir -p "''${XDG_CONFIG_HOME}/npm/node_global/lib"
      ${nodejs-wrapped}/bin/npx "$@"
    '';
  };

in
with lib; {
  options = {
    interpreters.nodejs = {
      enable = mkEnableOption ''
      Node.js JavaScript runtime
      Node.js is an open-source, cross-platform JavaScript runtime environment.
      '';

      version = mkOption {
        type = types.enum ["18" "20"];
        default = "20";
      };
    };
  };

  config = mkIf cfg.enable {
    replit = {
      packages = [
        nodejs-wrapped
        nodepkgs.pnpm
        nodepkgs.yarn
      ];

      runners.nodeJS = {
        name = "Node.js";
        displayVersion = nodejs.version;
        language = "javascript";
        start = "${nodejs-wrapped}/bin/node $file";
        fileParam = true;
      };

      env = {
        XDG_CONFIG_HOME = "$REPL_HOME/.config";
        npm_config_prefix = "$REPL_HOME/.config/npm/node_global";
        PATH = "${npx-wrapper}/bin:$XDG_CONFIG_HOME/npm/node_global/bin:$REPL_HOME/node_modules/.bin";
      };
    };
  };
}