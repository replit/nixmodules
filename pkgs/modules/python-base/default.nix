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
  python-ld-library-path = pythonUtils.python-ld-library-path;

  sitecustomize = pkgs.callPackage ../python/sitecustomize.nix { };

in
{
  id = "python-base-${pythonVersion}";
  name = "Python Tools";
  displayVersion = pythonVersion;
  description = ''
    Basic module for Python. Includes the interpreter and basic Replit
    configuration but nothing else. This may be combined with the
    pyright-extended module.
  '';

  replit.packages = [
    pypkgs.pip
    pkgs.poetry
    pkgs.uv
  ];

  replit.runners.python = {
    name = "Python ${pythonVersion}";
    displayVersion = python.version;
    fileParam = true;
    language = "python3";
    start = "${python}/bin/python3 $file";
    defaultEntrypoints = [ "main.py" "app.py" "run.py" ];
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
    PYTHONUSERBASE = userbase;
    PYTHONPATH = "${sitecustomize}";
    REPLIT_PYTHONPATH = "${userbase}/${python.sitePackages}:${pypkgs.setuptools}/${python.sitePackages}";
    UV_PROJECT_ENVIRONMENT = "$REPL_HOME/.pythonlibs";
    # Even though it is set-default in the wrapper, add it to the
    # environment too, so that when someone wants to override it,
    # they can keep the defaults if they want to.
    PYTHON_LD_LIBRARY_PATH = python-ld-library-path;
    PATH = "${userbase}/bin";
  };
}
