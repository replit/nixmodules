{ nodejs }:
{ pkgs, lib, ... }:

let
  nodejs-wrapped = pkgs.lib.mkWrapper-replit_ld_library_path nodejs;

  short-version = lib.versions.major nodejs.version;

  bun = pkgs.callPackage ../../bun { };

  nodepkgs = pkgs.nodePackages.override {
    inherit nodejs;
  };

  npx-wrapper = pkgs.writeShellApplication {
    name = "npx";
    text = ''
      mkdir -p "''${XDG_CONFIG_HOME}/npm/node_global/lib"
      ${nodejs-wrapped}/bin/npx "$@"
    '';
  };
in

{
  id = "nodejs-${short-version}";
  name = "Node.js Tools";
  displayVersion = nodejs.version;
  imports = [
    (import ../typescript-language-server {
      inherit nodepkgs;
    })
  ];

  replit = {
    packages = [
      nodejs-wrapped
      bun
      nodepkgs.pnpm
      nodepkgs.yarn
    ];

    dev.packages = [
      nodepkgs.prettier
    ];

    dev.languageServers.typescript-language-server.extensions = [ ".js" ".jsx" ".ts" ".tsx" ".json" ".mjs" ".cjs" ".es6" ];

    runners.nodeJS = {
      name = "Node.js";
      displayVersion = nodejs.version;
      language = "javascript";
      start = "${nodejs-wrapped}/bin/node $file";
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
      displayVersion = nodepkgs.prettier.version;
      language = "javascript";
      extensions = [ ".js" ".jsx" ".ts" ".tsx" ".json" ".html" ];
      start = {
        # Resolve to first prettier in path
        args = [ "prettier" "--stdin-filepath" "$file" ];
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
      PATH = "${npx-wrapper}/bin:$XDG_CONFIG_HOME/npm/node_global/bin:$REPL_HOME/node_modules/.bin";
    };

  };

}
