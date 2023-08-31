{ pkgs, lib, ... }:

let
  inherit (pkgs) erlang rebar3;

  version = lib.versions.major erlang.version;

  extensions = [ ".erl" ];
in

{
  id = "erlang-${version}";
  name = "Erlang/OTP ${version} Tools";

  packages = [
    erlang
    rebar3
  ];

  replit.runners.erlang = {
    name = "Erlang";
    language = "erlang";
    inherit extensions;
    fileParam = true;
    compile = "erlc -o $REPL_HOME/.build $file";
    start = "erl -noshell";
  };

  # TODO: LSP via pkgs.erlang-ls
}
