{ pkgs, lib, config, ... }:
let
  cfg = config.interpreters.bun;
  bun = pkgs.callPackage ../../../bun { };
  bun-wrapped = pkgs.lib.mkWrapper-replit_ld_library_path bun;
  extensions = [ ".js" ".jsx" ".cjs" ".mjs" ".ts" ".tsx" ".mts" ];
  lspExtensions = extensions ++ [ ".json" ];
in
with pkgs.lib; {

  options = {
    interpreters.bun = {
      enable = mkModuleEnableOption {
        name = "Bun";
        description = "Bun is a fast JavaScript runtime, package manager, and all-in-one toolkit";
      };

      version = mkOption {
        type = types.enum [bun.version];
        default = bun.version;
        description = "Bun version";
      };
    };
  };

  config = mkIf cfg.enable {
    displayVersion = bun.version;

    replit = {
      packages = [
        bun-wrapped
      ];
    };
  };
}
