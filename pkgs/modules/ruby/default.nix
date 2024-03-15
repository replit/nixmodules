{ ruby, rubyPackages }:
{ pkgs, lib, ... }:

let
  ruby-version = lib.versions.majorMinor "${ruby.version}";
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

{
  id = "ruby-${ruby-version}";
  name = "Ruby ${ruby-version} Tools";

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

  replit.dev.languageServers.solargraph = {
    name = "Solargraph: A Ruby Language Server";
    language = "ruby";

    displayVersion = "${rubyPackages.solargraph.version} (Ruby ${ruby-version})";

    start = "${rubyPackages.solargraph}/bin/solargraph stdio";
  };

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

  replit.env = {
    PATH = "${bundle-wrapper}/bin:$XDG_DATA_HOME/gem/ruby/${ruby-version}.0/bin";
  };
}
