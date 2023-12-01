{ nodejs, nodepkgs }:
{ pkgs, ... }:
let
  detect-typescript-path = pkgs.writeText "detect-typescript-path.cjs" ''
    const path = require('path');

    const fallbackPath = process.argv[process.argv.length - 1];

    try {
      const typescriptPath = require.resolve('typescript');
      const typescriptDir = path.dirname(typescriptPath);
      process.stdout.write(typescriptDir);
    } catch {
      process.stdout.write(fallbackPath);
    }
  '';

  typescript-language-server = nodepkgs.typescript-language-server.override {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postInstall = ''
      wrapProgram "$out/bin/typescript-language-server" \
        --suffix PATH : ${pkgs.lib.makeBinPath [ nodepkgs.typescript ]} # \
        # --add-flags '--tsserver-path "$(${nodejs}/bin/node ${detect-typescript-path} -- ${nodepkgs.typescript}/lib/node_modules/typescript/lib/)"'
    '';
  };
in
{
  replit.dev.languageServers.typescript-language-server = {
    name = "TypeScript Language Server";
    language = "javascript";
    start = "${typescript-language-server}/bin/typescript-language-server --stdio";
  };
}
