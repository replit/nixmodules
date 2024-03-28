{ pkgs, lib, config, ... }:
let
  cfg = config.debuggers.node-dap;
in
with pkgs.lib; {
  options = {
    debuggers.node-dap.enable = mkModuleEnableOption {
      name = "Node DAP";
      description = "a DAP-based JavaScript debugger for Node.js based on vscode-js-debug";
    };
  };

  config = mkIf cfg.enable {
    replit.dev.debuggers.node-dap = {
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
  };
}