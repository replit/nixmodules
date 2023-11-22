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
        ".js"
        ".ts"
      ];

      start = "${pkgs-unstable.nodejs}/bin/npm run start -- --host 0.0.0.0";
    };

    dev.languageServers.angular-language-server = {
      name = "Angular Language Server";
      language = "angular";
      extensions = [ ".html" ".js" ".jsx" ".ts" ".tsx" ];
      start = "${angular-language-server}/bin/ngserver --stdio";
    };
  };
}
