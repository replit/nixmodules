{ pkgs, config, ... }:
pkgs.lib.mkBundleModule {
  id = "ruby";
  name = "Ruby Tools Bundle";
  description = "Developer tools for the Ruby programming language";
  contents = [
    "interpreters.ruby"
    "languageServers.solargraph"
    "packagers.rubygems"
  ];
  inherit pkgs config;
}
