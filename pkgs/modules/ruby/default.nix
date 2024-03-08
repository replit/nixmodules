{ pkgs, lib, config, ... }:
let
  ruby-version = cfg.version;
  ruby-version-snakecased = builtins.replaceStrings ["."] ["_"] ruby-version;
  cfg = config.ruby;
  ruby = pkgs.${"ruby_${ruby-version-snakecased}"};
  rubyPackages = pkgs.${"rubyPackages_${ruby-version-snakecased}"};
  initial-gem-file = pkgs.writeTextFile {
    name = "Gemfile";
    text = ''
      source "https://rubygems.org"

      git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

      # gem "rails"
    '';
  };

  bundle-wrapper = pkgs.writeShellApplication {
    name = "bundle";
    text = ''
      if ! test -f "''${REPL_HOME}/Gemfile"; then
        cp ${initial-gem-file} "''${REPL_HOME}/Gemfile"
        chmod u+rw,g+r,o+r "''${REPL_HOME}/Gemfile"
      fi
      ${ruby}/bin/bundle "$@"
    '';
  };
in
with lib; {
  options = {
    ruby.enabled = mkOption {
      type = types.bool;
      default = false;
    };

    ruby.languageServer.enabled = mkOption {
      type = types.bool;
      default = false;
    };

    ruby.packager.enabled = mkOption {
      type = types.bool;
      default = false;
    };

    ruby.version = mkOption {
      type = types.enum ["3.1" "3.2"];
      default = "3.2";
    };
  };

  config = {
    ruby.languageServer.enabled = mkDefault cfg.enabled;
    ruby.packager.enabled = mkDefault cfg.enabled;

    replit.packages = mkIf cfg.enabled [
      ruby
    ];

    replit.runners.bundle = mkIf cfg.enabled {
      name = "bundle exec ruby";
      language = "ruby";

      compile = "${bundle-wrapper}/bin/bundle install";
      start = "${bundle-wrapper}/bin/bundle exec ruby $file";
      fileParam = true;
    };

    replit.dev.languageServers.solargraph = mkIf cfg.languageServer.enabled {
      name = "Solargraph: A Ruby Language Server";
      language = "ruby";

      displayVersion = "${rubyPackages.solargraph.version} (Ruby ${ruby-version})";

      start = "${rubyPackages.solargraph}/bin/solargraph stdio";
    };

    replit.packagers.gem = mkIf cfg.packager.enabled {
      name = "Gem";
      language = "ruby";
      displayVersion = "Ruby ${ruby-version}";
      features = {
        packageSearch = true;
        guessImports = true;
        enabledForHosting = false;
      };
    };

    replit.env = mkIf cfg.enabled {
      PATH = "${bundle-wrapper}/bin:$XDG_DATA_HOME/gem/ruby/${ruby-version}.0/bin";
    };
  };
}
