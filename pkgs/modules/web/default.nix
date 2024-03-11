{ pkgs, lib, config, ... }:
let cfg = config.web;
in with lib; {
  options = {
    web.enable = mkEnableOption "Web";
  };

  config = mkIf cfg.enable {
    typescript-language-server.enable = mkDefault true;
    typescript-language-server.extensions = mkDefault [ ".js" ".jsx" ".ts" ".tsx" ".mjs" ".mts" ".cjs" ".cts" ".es6" ];

    html-language-server.enable = mkDefault true;
    css-language-server.enable = mkDefault true;
  };
}
