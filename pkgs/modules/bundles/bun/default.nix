{ pkgs, lib, config, ... }:
let
  cfg = config.bundles.bun;
  bun = pkgs.callPackage ../../../bun { };
  bun-wrapped = pkgs.lib.mkWrapper-replit_ld_library_path bun;
  extensions = [ ".js" ".jsx" ".cjs" ".mjs" ".ts" ".tsx" ".mts" ];
  lspExtensions = extensions ++ [ ".json" ];
  bun-version = lib.versions.majorMinor bun.version;
in
with pkgs.lib; {
  options = {
    bundles.bun.enable = mkModuleEnableOption {
      name = "Bun Tools Bundle";
      description = "Development tools for the Bun JavaScript runtime";
    };
  };

  config = mkIf cfg.enable {
    interpreters.bun.enable = mkDefault true;
    languageServers.typescript-language-server.enable = mkDefault true;
    languageServers.typescript-language-server.extensions = mkDefault lspExtensions;
    packagers.bun.enable = mkDefault true;
  };
}
