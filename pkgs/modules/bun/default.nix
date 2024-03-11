{ pkgs, lib, config, ... }:
let
  cfg = config.bun;
  bun = pkgs.callPackage ../../bun { };
  bun-wrapped = pkgs.lib.mkWrapper-replit_ld_library_path bun;

  extensions = [ ".js" ".jsx" ".cjs" ".mjs" ".ts" ".tsx" ".mts" ];

  bun-version = lib.versions.majorMinor bun.version;
in
with lib; {

  options = {
    bun.enable = mkEnableOption "Bun";
  };

  config = mkIf cfg.enable {
    typescript-language-server.enable = mkDefault true;
    typescript-language-server.extensions = mkDefault (extensions ++ [ ".json" ]);

    displayVersion = bun.version;

    replit = mkIf cfg.enable {
      packages = [
        bun-wrapped
      ];

      dev.packagers.bun = {
        name = "bun";
        language = "bun";
        displayVersion = bun.version;
        features = {
          packageSearch = true;
          guessImports = true;
          enabledForHosting = false;
        };
      };
    };
  };
}
