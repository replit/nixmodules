{ pkgs, lib, config, ... }:
let
  cfg = config.packagers.bun;
in
with pkgs.lib; {
  options = {
    packagers.bun.enable = mkModuleEnableOption {
      name = "Bun package manager";
      description = "The Bun packager manager";
    };
  };

  config = mkIf cfg.enable {
    replit.dev.packagers.bun = {
      name = "bun";
      language = "bun";
      displayVersion = "Bun ${config.interpreters.bun.version}";
      features = {
        packageSearch = true;
        guessImports = true;
        enabledForHosting = false;
      };
    };
  };
}
