{ pkgs, ... }:

let
  nodejs = pkgs.nodejs_20;
  nodepkgs = nodejs.pkgs;

  vue-language-server = pkgs.callPackage ../../vue-language-server { };

  language = "vue";
  extensions = [ ".vue" ".js" ".mjs" ".cjs" ".jsx" ".ts" ".tsx" ".json" ".html" ".css" ];
in

{
  id = "vue-node-20";
  name = "Vue Tools with Node.js";
  displayVersion = "20";
  description = ''
    Vue.js development tools. Includes Node.js, Bun, pnpm, yarn, Vue language tools.
  '';

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
      start = "${nodejs}/bin/npm run dev";
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

