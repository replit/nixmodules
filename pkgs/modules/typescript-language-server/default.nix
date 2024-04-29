{ nodepkgs }:
{ pkgs, lib, ... }:
let
  typescript-language-server = nodepkgs.typescript-language-server.override {
    # TODO: we can get rid of this patch once >=4.2.0 is in the nixpkgs-unstable we use.
    # but we want this version because of https://github.com/typescript-language-server/typescript-language-server/pull/831
    version = "4.2.0";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/typescript-language-server/-/typescript-language-server-4.2.0.tgz";
      hash = "sha256-sg0O1uw6L3LDlPKTbXXsXVYwR+c7HH5c89xNIefEov8=";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];
    postInstall = ''
      wrapProgram "$out/bin/typescript-language-server" \
        --suffix PATH : ${pkgs.lib.makeBinPath [ nodepkgs.typescript ]}
    '';
  };
in
{
  id = lib.mkDefault "typescript-language-server";
  name = lib.mkDefault "TypeScript Language Server";
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
