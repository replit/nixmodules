{ pkgs, config, ... }:
pkgs.lib.mkBundleModule {
  id = "web";
  name = "Web Tools Bundle";
  description = "Tools for web development";
  contents = [
    "languageServers.typescript-language-server"
    "languageServers.html-language-server"
    "languageServers.css-language-server"
  ];
  inherit pkgs config;
}