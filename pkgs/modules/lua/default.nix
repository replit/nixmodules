{ pkgs, lib, ... }: {
  id = "lua";
  name = "Lua Tools";
  community-version = lib.versions.majorMinor pkgs.lua.version;
  version = "1.0";

  packages = with pkgs; [
    lua
  ];

  replit.runners.run = {
    name = "Lua script";
    language = "lua";

    start = "lua $file";
    fileParam = true;
  };

  replit.languageServers.sumneko = {
    name = "lua-language-server";
    language = "lua";

    start = "${pkgs.sumneko-lua-language-server}/bin/lua-language-server";
  };
}
