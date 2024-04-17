{ pkgs, lib, config, ... }:
with pkgs.lib;
let
  cfg = config.packagers.python;
  pythonVersion = config.interpreters.python.version;
  python = pkgs.python-versions.${pythonVersion}.python;
  pypkgs = pkgs.python-versions.${pythonVersion}.pythonPackages;
  pylibs-dir = ".pythonlibs";
  pip = import ./pip.nix (pkgs // {
    inherit python pypkgs;
  });
  pythonUtils = import ../../../python-utils {
    inherit pkgs python pypkgs;
  };
  pythonWrapper = pythonUtils.pythonWrapper;
  pip-wrapper = pythonWrapper { bin = "${pip.pip}/bin/pip"; name = "pip"; };
  poetry = pkgs.callPackage (../../../poetry/poetry-py + "${pythonVersion}.nix") {
    inherit python;
    inherit pypkgs;
  };
  poetry-config = pkgs.writeTextFile {
    name = "poetry-config";
    text = ''
  '';
    destination = "/config.toml";
  };
  poetry-wrapper = pythonWrapper { bin = "${poetry}/bin/poetry"; name = "poetry"; };
  versionSupported = pythonVersion != "3.8" && pythonVersion != "3.9";
in
{
  options = {
    packagers.python = {
      enable = mkModuleEnableOption {
        name = "Python packager";
        description = "Python packaging with Poetry or Pip";
      };
    };
  };

  config = mkIf (cfg.enable && versionSupported) {
    replit.packages = [
      pip-wrapper
      poetry-wrapper
    ];

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
    };
  };
}
