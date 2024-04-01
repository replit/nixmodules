{ pkgs, lib, config, ... }:
let
  cfg = config.bundles.nodejs;
in
with pkgs.lib; {
  options = {
    bundles.nodejs.enable = mkModuleEnableOption {
      name = "Node.js Tools Bundle";
      description = "Development tools for the Node.js JavaScript runtime";
    };
  };

  config = mkIf cfg.enable {
    interpreters.nodejs.enable = mkDefault true;
    # languageServers.typescript-language-server.enable = mkDefault true;
    # debuggers.node-dap.enable = mkDefault true;
    formatters.prettier.enable = mkDefault true;
    packagers.nodejs-packager.enable = mkDefault true;
  };
}