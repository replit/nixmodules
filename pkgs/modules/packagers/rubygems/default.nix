{ pkgs, lib, config, ... }:
let
  cfg = config.packagers.rubygems;
  ruby-version = config.interpreters.ruby.version;
in
with pkgs.lib; {
  options = {
    packagers.rubygems.enable = mkModuleEnableOption {
      name = "Rubygems";
      description = "Ruby packager support with Rubygems";
    };
  };

  config = mkIf cfg.enable {
    replit.packagers.gem = {
      name = "Gem";
      language = "ruby";
      displayVersion = "Ruby ${ruby-version}";
      features = {
        packageSearch = true;
        guessImports = true;
        enabledForHosting = false;
      };
    };
  };
}
