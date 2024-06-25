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

  formatter = import ../../formatter {
    inherit pkgs;
  };
  run-prettier = pkgs.writeShellApplication {
    name = "run-prettier";
    runtimeInputs = [ pkgs.bash nodepkgs.prettier ];
    extraShellCheckFlags = [ "-x" ];
    text = ''
      #!/bin/bash

      # Source the shared options parsing script
      source ${formatter}/bin/parse-formatter-options "$@"

      # Translate parsed arguments into prettier options
      prettier_args=()

      # Apply edit flag
      if [[ "''${apply:=false}" == "true" ]]; then
        prettier_args+=("--write")
      fi

      # Range options
      if [[ -n "$rangeStart" && -n "$rangeEnd" ]]; then
        prettier_args+=("--range-start" "$rangeStart" "--range-end" "$rangeEnd")
      fi

      # Tab size
      if [[ -n "$tabSize" ]]; then
        prettier_args+=("--tab-width" "$tabSize")
      fi

      # Insert spaces over tabs
      if [[ "''${insertSpaces:=false}" == "true" ]]; then
        prettier_args+=("--use-tabs" "false")
      else
        prettier_args+=("--use-tabs" "true")
      fi

      # Read file content from stdin if stdinMode is enabled
      if [[ "''${stdinMode:=false}" == "true" ]]; then
        prettier_args+=("--stdin-filepath")
      fi

      # Append the file path
      prettier_args+=("$file")

      # Execute the command
      # Resolve to first prettier in path
      prettier "''${prettier_args[@]}"
    '';
  };


in

{
  id = "nodejs-${short-version}";
  name = "Node.js Tools";
  description = ''
    Node.js development tools. Includes: Node.js ${nodejs.version}, TypeScript language server, pnpm, yarn, bun, Prettier code formatter, jsdebug.
  '';
  displayVersion = short-version;
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

    runners.nodeJS = {
      name = "Node.js";
      displayVersion = nodejs.version;
      language = "javascript";
      start = "${nodejs-wrapped}/bin/node $file";
      fileParam = true;
      defaultEntrypoints = [ "index.js" "main.js" ];
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
        args = [ "${run-prettier}/bin/run-prettier" "--stdin-filepath" "-f" "$file" ];
      };
      stdin = true;
    };

    dev.packagers.upmNodejs = {
      name = "Node.js packager (npm, yarn, pnpm, bun)";
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
