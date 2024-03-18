{ pkgs, lib, config, ... }:
let
  cfg = config.packagers.nodejs-packager;
in
with lib; {
  options = {
    packagers.nodejs-packager.enable = mkEnableOption ''
    Node.js Packager
    Package management for Node.js: supports one of npm, yarn, and pnpm.
    '';

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