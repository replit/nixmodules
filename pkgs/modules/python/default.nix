{ python, pypkgs }:
{ pkgs, lib, ... }:
let
  pythonVersion = lib.versions.majorMinor python.version;

  pylibs-dir = ".pythonlibs";

  userbase = "$REPL_HOME/${pylibs-dir}";

  pip = pkgs.callPackage ../../pip {
    inherit pypkgs;
  };

  pip-config = pkgs.writeTextFile {
    name = "pip.conf";
    text = ''
      [global]
      user = yes
      disable-pip-version-check = yes
      index-url = https://package-proxy.replit.com/pypi/simple/

      [install]
      use-feature = content-addressable-pool
      content-addressable-pool-symlink = yes
    '';
  };

  pythonUtils = import ../../python-utils {
    inherit pkgs python pypkgs;
  };
  pythonWrapper = pythonUtils.pythonWrapper;
  python-ld-library-path = pythonUtils.python-ld-library-path;

  pip-wrapper = pythonWrapper { bin = "${pip}/bin/pip"; name = "pip"; };

  poetry = pkgs.callPackage (../../poetry/poetry-py + "${pythonVersion}.nix") {
    inherit python;
    inherit pypkgs;
  };

  poetry-config = pkgs.writeTextFile {
    name = "poetry-config";
    text = ''
      [[tool.poetry.source]]
      name = "replit"
      url = "https://package-proxy.replit.com/pypi/simple/"
      default = true
    '';
    destination = "/conf.toml";
  };

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

  dapPython = pkgs.callPackage ../../dapPython {
    inherit pkgs python pypkgs debugpy;
  };

  debuggerConfig = {
    dapPython = {
      name = "DAP Python";
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

  pyright-extended = pkgs.callPackage ../../pyright-extended { };

in
{
  id = "python-${pythonVersion}";
  name = "Python ${pythonVersion} Tools";

  replit.packages = [
    python3-wrapper
  ];

  replit.dev.packages = [
    pip-wrapper
    poetry-wrapper
  ];

  replit.runners.python = {
    name = "Python ${pythonVersion}";
    fileParam = true;
    language = "python3";
    start = "${python3-wrapper}/bin/python3 $file";
  };

  replit.dev.debuggers = debuggerConfig;

  replit.dev.languageServers.pyright-extended = {
    name = "pyright-extended";
    language = "python3";
    start = "${pyright-extended}/bin/langserver.index.js --stdio";
  };

  replit.dev.packagers.upmPython = {
    name = "Python";
    language = "python3";
    ignoredPackages = [ "unit_tests" ];
    ignoredPaths = [ pylibs-dir ];
    features = {
      packageSearch = true;
      guessImports = true;
      enabledForHosting = false;
    };
  };

  replit.dev.env = {
    PIP_CONFIG_FILE = pip-config.outPath;
    POETRY_CONFIG_DIR = poetry-config.outPath;
    POETRY_CACHE_DIR = "$REPL_HOME/.cache/pypoetry";
    POETRY_VIRTUALENVS_CREATE = "0";
    POETRY_INSTALLER_MODERN_INSTALLATION = "0";
    POETRY_PIP_USE_PIP_CACHE = "1";
    POETRY_PIP_NO_ISOLATE = "1";
    POETRY_PIP_NO_PREFIX = "1";
    POETRY_PIP_FROM_PATH = "1";
    POETRY_USE_USER_SITE = "1";
    PYTHONUSERBASE = userbase;
  };

  replit.env = {
    PYTHONPATH = "${python}/lib/python${pythonVersion}:${userbase}/${python.sitePackages}";
    # Even though it is set-default in the wrapper, add it to the
    # environment too, so that when someone wants to override it,
    # they can keep the defaults if they want to.
    PYTHON_LD_LIBRARY_PATH = python-ld-library-path;
    PATH = "${userbase}/bin";
  };
}
