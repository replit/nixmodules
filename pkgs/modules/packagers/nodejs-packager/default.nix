{ pkgs, lib, config, ... }:
let
  cfg = config.packagers.nodejs-packager;
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
      features = {
        packageSearch = true;
        guessImports = true;
        enabledForHosting = false;
      };
    };
  };
}