{ pkgs, lib, config, ... }:
let
  cfg = config.packagers.nodejs-packager;
  # nodejs = pkgs.${"nodejs_${config.interpreters.nodejs.version}"};
  nodejs = config.interpreters.nodejs._package;
in
with pkgs.lib; {
  options = {
    packagers.nodejs-packager.enable = mkModuleEnableOption {
      name = "Node.js Packager";
      description = "Package management for Node.js: supports one of npm, yarn, and pnpm";
    };
  };

  config = mkIf cfg.enable {
    replit.dev.packagers.nodejs-packager = {
      name = "Node.js packager";
      language = "nodejs";
      displayVersion = "Node ${nodejs.version}";
      features = {
        packageSearch = true;
        guessImports = true;
        enabledForHosting = false;
      };
    };
  };
}
