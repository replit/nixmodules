{ pkgs, lib, config, ... }:
let
  cfg = config.interpreters.ruby;
  ruby-version = cfg.version;
  ruby-version-snakecased = builtins.replaceStrings ["."] ["_"] ruby-version;
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
with pkgs.lib; {
  options = {
    interpreters.ruby = {
      enable = mkModuleEnableOption {
        name = "Ruby Programming Language";
        description = "A dynamic, open source programming language with a focus on simplicity and productivity";
      };

      version = mkOption {
        type = types.enum ["3.1" "3.2"];
        default = "3.2";
        description = "Ruby version";
      };

      _rubyPackages = mkOption {
        type = types.anything;
        description = "rubyPackages attr on nixpkgs to use: for internal use.";
        default = null;
      };
    };
  };

  config = mkIf cfg.enable {
    interpreters.ruby._rubyPackages = mkForce rubyPackages;

    replit.packages = [
      ruby
    ];

    replit.runners.bundle = {
      name = "bundle exec ruby";
      language = "ruby";

      compile = "${bundle-wrapper}/bin/bundle install";
      start = "${bundle-wrapper}/bin/bundle exec ruby $file";
      fileParam = true;
    };

    replit.env = {
      PATH = "${bundle-wrapper}/bin:$XDG_DATA_HOME/gem/ruby/${ruby-version}.0/bin:${ruby}/bin";
    };
  };
}
