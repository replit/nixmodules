{ pkgs, lib, ... }:

let
  inherit (pkgs) love;

  version = lib.versions.major love;
in

{
  id = "love2d-${version}";
  name = "Love2D Tools";

  packages = [
    love
    pkgs.lua
  ];

  replit.runners.love = {
    name = "Love2D";
    language = "lua";
    start = "${love}/bin/love $REPL_HOME";
  };
}
