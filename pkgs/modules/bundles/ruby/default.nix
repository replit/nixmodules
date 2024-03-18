{ pkgs, lib, config, ... }:
let
  cfg = config.bundles.ruby;
in
with pkgs.lib; {
  options = {
    bundles.ruby.enable = mkModuleEnableOption {
      name = "Ruby Tools Bundle";
      description = "Developer tools for the Ruby programming language";
    };
  };

  config = mkIf cfg.enable {
    interpreters.ruby.enable = mkDefault true;
    languageServers.solargraph.enable = mkDefault true;
    packagers.rubygems.enable = mkDefault true;
  };
}
