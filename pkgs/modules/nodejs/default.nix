{ nodejs }:
{ pkgs, pkgs-unstable, lib, ... }:

let
  community-version = lib.versions.major nodejs.version;

  bun = pkgs-unstable.callPackage ../../bun { };

  nodepkgs = pkgs.nodePackages.override {
    inherit nodejs;
  };

  prettier = nodepkgs.prettier;
in

{
  id = "nodejs-${community-version}";
  name = "Node.js ${community-version} Tools";
  imports = [
    (import ../typescript-language-server {
      inherit nodepkgs;
    })
  ];

  replit = {
    packages = [
      nodejs
    ];

    dev.packages = [
      bun
      prettier
      nodepkgs.pnpm
      nodepkgs.yarn
    ];

    dev.languageServers.typescript-language-server.extensions = [ ".js" ".jsx" ".ts" ".tsx" ".json" ".mjs" ".cjs" ".es6" ];

    runners.nodeJS = {
      name = "Node.js";
      language = "javascript";
      start = "${nodejs}/bin/node $file";
      fileParam = true;
    };

    dev.debuggers.nodeDAP = {
      name = "Node DAP";
      language = "javascript";
      transport = "localhost:0";
      fileParam = true;
      start = {
        args = [ "dap-node" ];
      };
      initializeMessage = {
        command = "initialize";
        type = "request";
        arguments = {
          clientID = "replit";
          clientName = "replit.com";
          adapterID = "dap-node";
          columnsStartAt1 = true;
          linesStartAt1 = true;
          locale = "en-us";
          pathFormat = "path";
          supportsInvalidatedEvent = true;
          supportsProgressReporting = true;
          supportsRunInTerminalRequest = true;
          supportsVariablePaging = true;
          supportsVariableType = true;
        };
      };
      launchMessage = {
        command = "launch";
        type = "request";
        arguments = {
          args = [ ];
          console = "externalTerminal";
          cwd = ".";
          environment = [ ];
          pauseForSourceMap = false;
          program = "./$file";
          request = "launch";
          sourceMaps = true;
          stopOnEntry = false;
          type = "pwa-node";
        };
      };
    };

    dev.formatters.prettier = {
      name = "Prettier";
      language = "javascript";
      extensions = [ ".js" ".jsx" ".ts" ".tsx" ".json" ];
      start = {
        args = [ "${prettier}/bin/prettier" "--stdin-filepath" "$file" ];
      };
      stdin = true;
    };

    dev.packagers.upmNodejs = {
      name = "UPM for Node.js";
      language = "nodejs";
      features = {
        packageSearch = true;
        guessImports = true;
        enabledForHosting = false;
      };
    };

    env = {
      XDG_CONFIG_HOME = "$REPL_HOME/.config";
      npm_config_prefix = "$REPL_HOME/.config/npm/node_global";
      PATH = "$REPL_HOME/.config/npm/node_global/bin:$REPL_HOME/node_modules/.bin";
    };

  };

}
