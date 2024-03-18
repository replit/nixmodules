{ pkgs, lib, config, ... }:
let
  cfg = config.packagers.rubygems;
  ruby-version = config.interpreters.ruby.version;
in
with lib; {
  options = {
    packagers.rubygems.enable = mkEnableOption ''
    Rubygems
    Ruby packager support with Rubygems.
    '';
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