{ pkgs, lib, ... }:

let
  elixir-version = builtins.replaceStrings [ "." ] [ "_" ] (lib.versions.majorMinor "${pkgs.elixir.version}");
in

{
  id = "elixir-${elixir-version}";
  name = "Elixir ${elixir-version} Tools";
  displayVersion = elixir-version;
  description = ''
    Development tools for Elixir. Includes Elixir and Elixir language server.
  '';

  replit.packages = [
    pkgs.elixir
    pkgs.elixir-ls
  ];

  replit.runners.elixir = {
    name = "mix run";
    language = "elixir";
    start = "${pkgs.elixir}/bin/mix run";
  };

  replit.dev.languageServers.elixir = {
    name = "Elixir Language Server (ElixirLS)";
    language = "elixir";
    start = "${pkgs.elixir-ls}/bin/elixir-ls";
  };

  replit.env = {
    HEX_HOME = "$REPL_HOME/.hex";
    MIX_HOME = "$REPL_HOME/.mix";
  };
}
