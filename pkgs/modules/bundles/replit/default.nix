{ pkgs, config, ... }:
pkgs.lib.mkBundleModule {
  id = "replit";
  name = "Replit Bundle";
  description = "Tool bundle for working with Repls";
  submodules = [
    "languageServers.dotreplit-lsp"
  ];
  enableDefault = true;
  inherit pkgs config;
}
