{ pkgs, lib, config, ... }:
let cfg = config.bundles.web;
in with pkgs.lib; {
  options = {
    bundles.web.enable = mkModuleEnableOption {
      name = "Web";
      description = "Tools for web development";
    };
  };

  config = mkIf cfg.enable {
    languageServers.typescript-language-server.enable = mkDefault true;
    languageServers.typescript-language-server.extensions = mkDefault [ ".js" ".jsx" ".ts" ".tsx" ".mjs" ".mts" ".cjs" ".cts" ".es6" ];

    languageServers.html-language-server.enable = mkDefault true;
    languageServers.css-language-server.enable = mkDefault true;
  };
}
