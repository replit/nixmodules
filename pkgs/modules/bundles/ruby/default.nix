{ pkgs, lib, config, ... }:
let
  cfg = config.bundles.ruby;
in
with lib; {
  options = {
    bundles.ruby.enable = mkEnableOption ''
    Ruby Tools Bundle
    Developer tools for the Ruby programming language.
    '';
  };

  config = mkIf cfg.enable {
    interpreters.ruby.enable = mkDefault true;
    languageServers.solargraph.enable = mkDefault true;
    packagers.rubygems.enable = mkDefault true;
  };
}
