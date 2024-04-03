{ pkgs, lib, config, ... }:
let
  cfg = config.interpreters.nodejs;
  availableVersions = {
    ${pkgs.nodejs_18.version} = pkgs.nodejs_18;
    ${pkgs.nodejs_20.version} = pkgs.nodejs_20;
  };
  nodejs = availableVersions.${cfg.version};
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
with pkgs.lib; {
  options = {
    interpreters.nodejs = {
      enable = mkModuleEnableOption {
        name = "Node.js JavaScript runtime";
        description = "Node.js is an open-source, cross-platform JavaScript runtime environment";
      };

      version = mkOption {
        type = types.enum (attrNames availableVersions);
        description = "Node.js version";
      };

      _nodejs = mkOption {
        type = types.package;
        description = "Choose version of nodejs; internal use";
      };

    };

  };

  config = mkIf cfg.enable {
    interpreters.nodejs._nodejs = mkForce nodejs;

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