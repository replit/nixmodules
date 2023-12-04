{ nodepkgs }:
{ pkgs, ... }:
let
  typescript-language-server = pkgs.importPackage ../../typescript-language-server {};

  # typescript-language-server = nodepkgs.typescript-language-server.override {
  #   nativeBuildInputs = [ pkgs.makeWrapper ];
  #   postInstall = ''
  #     wrapProgram "$out/bin/typescript-language-server" \
  #       --suffix PATH : ${pkgs.lib.makeBinPath [ nodepkgs.typescript ]}
  #   '';
  # };
in
{
  replit.dev.languageServers.typescript-language-server = {
    name = "TypeScript Language Server";
    language = "javascript";
    start = "${typescript-language-server}/bin/typescript-language-server --stdio";

    initializationOptions = {
      tsserver.fallbackPath = "${nodepkgs.typescript}/lib/node_modules/typescript/lib";
    };
  };
}
