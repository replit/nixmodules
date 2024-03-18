{ pkgs, lib, config, ... }:
let
  cfg = config.languageServers.solargraph;
  ruby-version = config.interpreters.ruby.version;
  rubyPackages = config.interpreters.ruby._rubyPackages;
in
with lib;
{
  options = {
    languageServers.solargraph.enable = mkEnableOption ''
    Solargraph - a Ruby Language Server
    Solargraph is a Ruby gem that provides intellisense features through Microsoft's language server protocol.
    '';
  };
  config = mkIf cfg.enable {
    replit.dev.languageServers.solargraph =  {
      name = "Solargraph: A Ruby Language Server";
      language = "ruby";

      displayVersion = "${rubyPackages.solargraph.version} (Ruby ${ruby-version})";

      start = "${rubyPackages.solargraph}/bin/solargraph stdio";
    };
  };
}