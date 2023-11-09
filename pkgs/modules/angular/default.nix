{ pkgs-unstable, ... }:

let
  angular-language-server = pkgs-unstable.callPackage ../../angular-language-server {};
in

{
  id = "angular-node-20";
  name = "Angular with Node.js 20 Tools";

  replit = {
    packages = with pkgs-unstable; [
      nodejs
    ];

    env = {
      PATH = "$REPL_HOME/node_modules/.bin";
    };

    # Nothing required for deployment because app compiles to a static site
    dev.runners.dev-server = {
      name = "package.json dev script";
      language = "svelte";
      extensions = [
        ".html"
        ".css"
        ".js"
        ".ts"
      ];

      start = "${pkgs-unstable.nodejs}/bin/npm run serve --host 0.0.0.0";
    };

    dev.languageServers.svelte-language-server = {
      name = "Svelte Language Server";
      language = "svelte";
      extensions = [ ".svelte" ".js" ".ts" ];
      start = "${angular-language-server}/bin/ngserver --stdio";
    };
  };
}
