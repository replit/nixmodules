{ pkgs, config, ... }:
pkgs.lib.mkBundleModule {
  id = "nodejs";
  name = "Node.js Tools Bundle";
  description = "Development tools for the Node.js JavaScript runtime";
  submodules = [
    "interpreters.nodejs"
    "languageServers.typescript-language-server"
    "debuggers.node-dap"
    "formatters.prettier"
    "packagers.nodejs-packager"
  ];
  inherit pkgs config;
}
