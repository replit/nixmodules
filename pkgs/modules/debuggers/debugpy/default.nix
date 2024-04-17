{ pkgs, config, lib, ... }:
with pkgs.lib;
let
  cfg = config.debuggers.debugpy;
  pythonVersion = config.interpreters.python.version;
  python = pkgs.python-versions.${pythonVersion}.python;
  pypkgs = pkgs.python-versions.${pythonVersion}.pythonPackages;
  debugpy = pypkgs.debugpy.overridePythonAttrs
    (old: rec {
      disabled = false;
      version = "1.8.0";
      src = pkgs.fetchFromGitHub {
        owner = "microsoft";
        repo = "debugpy";
        rev = "refs/tags/v${version}";
        hash = "sha256-FW1RDmj4sDBS0q08C82ErUd16ofxJxgVaxfykn/wVBA=";
      };
      doCheck = false;
    });

  dapPython = pkgs.callPackage ../../../dapPython {
    inherit pkgs python pypkgs debugpy;
  };

  debuggerConfig = {
    debugpy = {
      name = "debugpy";
      displayVersion = dapPython.version;
      language = "python3";
      start = {
        args = [ "${dapPython}/bin/dap-python" "$file" ];
      };
      fileParam = true;
      transport = "localhost:0";
      integratedAdapter = {
        dapTcpAddress = "localhost:0";
      };
      initializeMessage = {
        command = "initialize";
        type = "request";
        arguments = {
          adapterID = "debugpy";
          clientID = "replit";
          clientName = "replit.com";
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
        command = "attach";
        type = "request";
        arguments = {
          logging = { };
        };
      };
    };
  };
in
{
  options = {
    debuggers.debugpy = {
      enable = mkModuleEnableOption {
        name = "debugpy";
        description = "An implementation of the Debug Adapter Protocol for Python 3";
      };
    };
  };

  config = mkIf cfg.enable {
    replit.dev.debuggers = debuggerConfig;
  };
}
