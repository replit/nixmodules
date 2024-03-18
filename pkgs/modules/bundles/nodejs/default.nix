{ pkgs, lib, config, ... }:
let
  cfg = config.bundles.nodejs;
in
with lib; {
  options = {
    bundles.nodejs.enable = mkEnableOption ''
    Node.js Tools Bundle
    Development tools for the Node.js JavaScript runtime.
    '';
  };

  config = mkIf cfg.enable {
    interpreters.nodejs.enable = mkDefault true;
    languageServers.typescript-language-server.enable = mkDefault true;
    debuggers.js-debug.enable = mkDefault true;
    formatters.prettier.enable = mkDefault true;
    packagers.nodejs-packager.enable = mkDefault true;
  };
}