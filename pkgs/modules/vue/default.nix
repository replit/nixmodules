{ pkgs, ... }:

let
  inherit (pkgs) nodejs;
  nodepkgs = nodejs.pkgs;

  vue-language-server = pkgs.callPackage ../../vue-language-server { };

  language = "vue";
  extensions = [ ".vue" ".js" ".mjs" ".cjs" ".jsx" ".ts" ".tsx" ".json" ".html" ".css" ];
in

{
  id = "vue-node-18";
  name = "Vue with Node.js 18 Tools";

  replit = {
    packages = [
      pkgs.bun
      nodejs
      nodepkgs.pnpm
      nodepkgs.yarn
    ];

    dev.runners.dev-runner = {
      name = "package.json dev script";
      inherit language extensions;
      start = "${pkgs.nodejs}/bin/npm run dev";
    };

    dev.languageServers.vue-language-server = {
      name = "Vue Language Server";
      inherit language extensions;
      start = "${vue-language-server}/bin/vue-language-server --stdio";

      initializationOptions = {
        typescript.tsdk = "${nodepkgs.typescript}/lib/node_modules/typescript/lib";
      };
    };
  };
}

