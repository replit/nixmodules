{ pkgs, config, ... }:
pkgs.lib.mkBundleModule {
  id = "go";
  name = "Go Tools Bundle";
  description = "Development tools for the Go programming language";
  submodules = [
    "compilers.go"
    "languageServers.gopls"
    "formatters.gofmt"
  ];
  inherit pkgs config;
}
