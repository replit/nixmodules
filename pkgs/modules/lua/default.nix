{ pkgs, lib, ... }:
let lua-version = lib.versions.majorMinor pkgs.lua.version;
in
{
  id = "lua-${lua-version}";
  name = "Lua Tools";
  displayVersion = lua-version;
  description = ''
    Lua development tools. Includes:
    * Lua
    * Lua language server
  '';

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

    start = "${pkgs.sumneko-lua-language-server}/bin/lua-language-server";
  };
}
