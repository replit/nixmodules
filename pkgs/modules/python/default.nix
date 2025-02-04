{ python, pypkgs }:
{ pkgs-unstable, pkgs-23_05, lib, ... }:
let
  pythonVersion = lib.versions.majorMinor python.version;

  pkgs = pkgs-unstable;

  pylibs-dir = ".pythonlibs";

  userbase = "$REPL_HOME/${pylibs-dir}";

  pythonUtils = import ../../python-utils {
    inherit pkgs python pypkgs;
  };
  pythonWrapper = pythonUtils.pythonWrapper;
  python-ld-library-path = pythonUtils.python-ld-library-path;

  pip = import ./pip.nix (pkgs // {
    inherit python pypkgs;
  });
  pip-wrapper = pythonWrapper { bin = "${pip.pip}/bin/pip"; name = "pip"; };

  poetry = pkgs.callPackage (../../poetry/poetry-py + "${pythonVersion}.nix") {
    inherit python;
    inherit pypkgs;
  };

  poetry-config = pkgs.writeTextFile {
    name = "poetry-config";
    text = ''
    '';
    destination = "/config.toml";
  };

  dapPython = pkgs.callPackage ../../dapPython {
    inherit pkgs python pypkgs;
  };

  debuggerConfig = {
    dapPython = {
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

  python3-wrapper = pythonWrapper { bin = "${python}/bin/python3"; name = "python3"; aliases = [ "python" "python${pythonVersion}" ]; };

  poetry-wrapper = pythonWrapper { bin = "${poetry}/bin/poetry"; name = "poetry"; };

  binary-wrapped-python = pkgs.callPackage ../../python-wrapped {
    inherit pkgs python python-ld-library-path;
  };

  pyright-extended = pkgs.callPackage ../../pyright-extended {
    yapf = pypkgs.yapf;
  };

  sitecustomize = pkgs.callPackage ./sitecustomize.nix { };

  uv = pkgs.callPackage ./uv {
    rustPlatform = (
      let
        toolchain = pkgs.fenix.latest.toolchain;
      in
      pkgs.makeRustPlatform {
        cargo = toolchain;
        rustc = toolchain;
      }
    );
  };

in
{
  id = "python-${pythonVersion}";
  name = "Python Tools";
  displayVersion = pythonVersion;
  description = ''
    Development tools for Python. Includes Python interpreter, Pip, Poetry, Pyright extended language server, debugpy debugger.
  '';

  replit.packages = [
    binary-wrapped-python
    pip-wrapper
    poetry-wrapper
    uv
  ];

  replit.runners.python = {
    name = "Python ${pythonVersion}";
    displayVersion = python.version;
    fileParam = true;
    language = "python3";
    start = "${python3-wrapper}/bin/python3 $file";
    defaultEntrypoints = [ "main.py" "app.py" "run.py" ];
  };

  replit.dev.debuggers = debuggerConfig;

  replit.dev.languageServers.pyright-extended = {
    name = "pyright-extended";
    displayVersion = pyright-extended.version;
    language = "python3";
    start = "${pyright-extended}/bin/langserver.index.js --stdio";
  };

  replit.dev.packagers.upmPython = {
    name = "Python packager";
    language = "python3";
    ignoredPackages = [ "unit_tests" ];
    ignoredPaths = [ pylibs-dir ];
    features = {
      packageSearch = true;
      guessImports = true;
      enabledForHosting = false;
    };
  };

  replit.env = {
    POETRY_CONFIG_DIR = poetry-config.outPath;
    POETRY_CACHE_DIR = "$REPL_HOME/.cache/pypoetry";
    POETRY_VIRTUALENVS_CREATE = "0";
    POETRY_INSTALLER_MODERN_INSTALLATION = "1";
    POETRY_DOWNLOAD_WITH_CURL = "1";
    POETRY_PIP_USE_PIP_CACHE = "1";
    POETRY_PIP_NO_ISOLATE = "1";
    POETRY_PIP_NO_PREFIX = "1";
    POETRY_PIP_FROM_PATH = "1";
    POETRY_USE_USER_SITE = "1";
    PIP_CONFIG_FILE = pip.config.outPath;
    PYTHONUSERBASE = userbase;
    PYTHONPATH = "${sitecustomize}:${pip.sitePackages}";
    REPLIT_PYTHONPATH = "${userbase}/${python.sitePackages}:${pypkgs.setuptools}/${python.sitePackages}";
    UV_PROJECT_ENVIRONMENT = "$REPL_HOME/.pythonlibs";
    UV_PYTHON_DOWNLOADS = "never";
    UV_PYTHON_PREFERENCE = "only-system";
    # Even though it is set-default in the wrapper, add it to the
    # environment too, so that when someone wants to override it,
    # they can keep the defaults if they want to.
    REPLIT_PYTHON_LD_LIBRARY_PATH = python-ld-library-path;
    PATH = "${userbase}/bin";
  };
}
