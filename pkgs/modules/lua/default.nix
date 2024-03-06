{ pkgs, lib, ... }:
let lua-version = lib.versions.majorMinor pkgs.lua.version;
in
{
  id = "lua-${lua-version}";
  name = "Lua Tools";

  replit.packages = with pkgs; [
    lua
  ];

  replit.runners.run = {
    name = "Lua script";
    language = "lua";

    start = "lua $file";
    fileParam = true;
  };

  replit.dev.languageServers.sumneko = {
    name = "lua-language-server";
    language = "lua";
    displayVersion = pkgs.sumneko-lua-language-server.version;

    start = "${pkgs.sumneko-lua-language-server}/bin/lua-language-server";
  };
}
