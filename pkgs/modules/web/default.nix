{ pkgs, lib, config, ... }:
let cfg = config.bundles.web;
in with lib; {
  options = {
    bundles.web.enable = mkEnableOption "Web";
    v1bundles.web.enable = mkEnableOption "Web";
  };

  config = mkIf cfg.enable {
    languageServers.typescript-language-server.enable = mkDefault true;
    languageServers.typescript-language-server.extensions = mkDefault [ ".js" ".jsx" ".ts" ".tsx" ".mjs" ".mts" ".cjs" ".cts" ".es6" ];

    languageServers.html-language-server.enable = mkDefault true;
    languageServers.css-language-server.enable = mkDefault true;
  };
}

# bundles
# languageServers
# packagers
# * upm configs?
# formatters