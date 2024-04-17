{ pkgs, config, ... }:
pkgs.lib.mkBundleModule {
  id = "bun";
  name = "Bun Tools Bundle";
  description = "Development tools for the Bun JavaScript runtime";
  submodules = [
    "interpreters.bun"
    "languageServers.typescript-language-server"
    "packagers.bun"
  ];
  inherit pkgs config;
}
