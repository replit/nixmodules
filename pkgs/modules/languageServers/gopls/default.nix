{ lib, config, pkgs, ... }:
let cfg = config.languageServers.gopls;
gopls = pkgs.gopls;
in
with pkgs.lib; {
  options = {
    languageServers.gopls.enable = mkModuleEnableOption {
      name = "Gopls - Go language server";
      description = ''(pronounced "Go please") is the official Go language server developed by the Go team'';
    };

    languageServers.gopls.version = mkOption {
      type = types.enum [gopls.version];
      default = gopls.version;
    };
  };

  config = mkIf cfg.enable {
    replit.dev.packages = [
      gopls
    ];

    replit.dev.languageServers.gopls = {
      name = "gopls";
      language = "go";

      displayVersion = gopls.version;

      start = "${gopls}/bin/gopls";
    };
  };
}