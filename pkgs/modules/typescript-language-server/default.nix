{ nodepkgs }:
{ pkgs, lib, ... }:
let
  inherit (nodepkgs) typescript-language-server;
in
{
  id = lib.mkDefault "typescript-language-server";
  name = lib.mkDefault "TypeScript Language Server";
  description = lib.mkDefault ''
    TypeScript (& JavaScript) language server
  '';
  replit.dev.languageServers.typescript-language-server = {
    name = "TypeScript Language Server";
    displayVersion = typescript-language-server.version;
    language = "javascript";
    start = "${typescript-language-server}/bin/typescript-language-server --stdio";

    initializationOptions = {
      tsserver.fallbackPath = "${nodepkgs.typescript}/lib/node_modules/typescript/lib";
    };

    extensions = [ ".js" ".jsx" ".ts" ".tsx" ".mjs" ".mts" ".cjs" ".cts" ".es6" ".json" ];
  };
}
