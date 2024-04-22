{ pkgs, config, ... }:
pkgs.lib.mkBundleModule {
  id = "python";
  name = "Python Tools Bundle";
  description = "Development tools for the Python 3 runtime";
  submodules = [
    "interpreters.python"
    "languageServers.pyright-extended"
    "packagers.python"
    "debuggers.debugpy"
  ];
  inherit pkgs config;
}
