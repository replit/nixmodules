{ pkgs, lib, ... }:

let
  inherit (pkgs) elixir;

  extensions = [ ".exs" ];

  version = lib.versions.majorMinor elixir.version;
in

{
  id = "elixir-${version}";
  name = "Elixir ${version} Tools";

  packages = [
    elixir
  ];

  replit.env = {
    LC_ALL = "en_US.UTF-8";
    HEX_HOME = "$REPL_HOME/.hex";
    MIX_HOME = "$REPL_HOME/.mix";
  };

  replit.runners.elixir = {
    name = "Elixir";
    language = "elixir";
    inherit extensions;
    fileParam = true;
    start = "${elixir}/bin/elixir $file";
  };

  # TODO: LSP *and* DAP via pkgs.elixir-ls
}
