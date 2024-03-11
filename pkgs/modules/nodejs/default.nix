{ pkgs, lib, config, ... }:
let
  cfg = config.nodejs;
  nodejs = pkgs.${"nodejs_${cfg.version}"};
  nodepkgs = pkgs.nodePackages.override {
    inherit nodejs;
  };

  nodejs-wrapped = pkgs.lib.mkWrapper-replit_ld_library_path nodejs;

  short-version = lib.versions.major nodejs.version;

  npx-wrapper = pkgs.writeShellApplication {
    name = "npx";
    text = ''
      mkdir -p "''${XDG_CONFIG_HOME}/npm/node_global/lib"
      ${nodejs-wrapped}/bin/npx "$@"
    '';
  };
in
with lib; {
  options = {
    nodejs.enable = mkEnableOption "Node.js Tools";

    nodejs.version = mkOption {
      type = types.enum ["18" "20"];
      default = "20";
    };

    nodejs.packager.enable = mkEnableOption "Node.js Packager";

    nodejs.debugger.enable = mkEnableOption "Node.js Debugger";

  };

  config = mkIf cfg.enable {
    nodejs.packager.enable = mkDefault true;
    nodejs.debugger.enable = mkDefault true;
    typescript-language-server.enable = mkDefault true;
    typescript-language-server.extensions = mkDefault [ ".js" ".jsx" ".ts" ".tsx" ".json" ".mjs" ".cjs" ".es6" ];
    typescript-language-server.nodejsVersion = mkDefault cfg.version;
    prettier.enable = mkDefault true;
    prettier.nodejsVersion = mkDefault cfg.version;

    replit = {
      packages = [
        nodejs-wrapped
        nodepkgs.pnpm
        nodepkgs.yarn
      ];

      runners.nodeJS = {
        name = "Node.js";
        displayVersion = nodejs.version;
        language = "javascript";
        start = "${nodejs-wrapped}/bin/node $file";
        fileParam = true;
      };

      dev.debuggers.nodeDAP = mkIf cfg.debugger.enable {
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

      dev.packagers.nodejsPackager = mkIf cfg.packager.enable {
        name = "Node.js packager";
        language = "nodejs";
        displayVersion = "Node ${lib.versions.majorMinor nodejs.version}";
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
  };
}
