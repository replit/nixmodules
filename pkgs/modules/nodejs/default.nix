{ nodejs }:
{ pkgs, lib, ... }:

let
  nodejs-wrapped = pkgs.stdenvNoCC.mkDerivation {
    name = "nodejs-wrapped";
    buildInputs = [ pkgs.makeWrapper ];
    buildCommand = ''
      mkdir -p $out/bin
      for bin in ${nodejs}/bin/*; do
        local binName=$(basename $bin)
        cat >$out/bin/$binName <<-EOF
      if [ -n "\$REPLIT_LD_LIBRARY_PATH" ]; then
        export LD_LIBRARY_PATH="\$REPLIT_LD_LIBRARY_PATH:\$LD_LIBRARY_PATH"
      fi
      exec "$bin" "\$@"
      EOF
        chmod +x $out/bin/$binName
      done
    '';

    inherit (nodejs) meta version;
  };

  community-version = lib.versions.major nodejs.version;

  bun = pkgs.callPackage ../../bun { };

  nodepkgs = pkgs.nodePackages.override {
    inherit nodejs;
  };

  prettier = nodepkgs.prettier;

  npx-wrapper = pkgs.writeShellScriptBin "npx" ''
    mkdir -p ''${XDG_CONFIG_HOME}/npm/node_global/lib
    ${nodejs-wrapped}/bin/npx "$@"
  '';
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
      nodejs-wrapped
      bun
      nodepkgs.pnpm
      nodepkgs.yarn
    ];

    dev.packages = [
      prettier
    ];

    dev.languageServers.typescript-language-server.extensions = [ ".js" ".jsx" ".ts" ".tsx" ".json" ".mjs" ".cjs" ".es6" ];

    runners.nodeJS = {
      name = "Node.js";
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
      language = "javascript";
      extensions = [ ".js" ".jsx" ".ts" ".tsx" ".json" ".html" ];
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
      PATH = "${npx-wrapper}/bin:$XDG_CONFIG_HOME/npm/node_global/bin:$REPL_HOME/node_modules/.bin";
    };

  };

}
