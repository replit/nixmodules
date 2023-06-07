{ python, pypkgs }:
{ pkgs, lib, ... }:
let
  community-version = lib.versions.majorMinor python.version;

  pylibs-dir = ".pythonlibs";

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

  poetry = pkgs.callPackage ../../poetry {
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

  prybar-python = pkgs.prybar.prybar-python310;

  stderred = pkgs.callPackage ../../stderred { };

  debugpy = pypkgs.debugpy;

  dapPython = pkgs.callPackage ../../dapPython { };

  python-lsp-server = pkgs.callPackage ../../python-lsp-server {
    inherit pypkgs;
  };

  python-ld-library-path = pkgs.lib.makeLibraryPath [
    # Needed for pandas / numpy
    pkgs.stdenv.cc.cc.lib
    pkgs.zlib
    # Needed for pygame
    pkgs.glib
    # Needed for matplotlib
    pkgs.xorg.libX11
  ];

  python3-wrapper = pkgs.stdenvNoCC.mkDerivation {
    name = "python3-wrapper";
    buildInputs = [ pkgs.makeWrapper ];

    buildCommand = ''
      mkdir -p $out/bin
      makeWrapper ${python}/bin/python3 $out/bin/python3 \
        --set LD_LIBRARY_PATH "${python-ld-library-path}"
    
      ln -s $out/bin/python3 $out/bin/python
      ln -s $out/bin/python3 $out/bin/python${community-version}
    '';
  };

  run-prybar = pkgs.writeShellScriptBin "run-prybar" ''
    export LD_LIBRARY_PATH="${python-ld-library-path}"
    ${stderred}/bin/stderred -- ${prybar-python}/bin/prybar-python310 -q --ps1 "''$(printf '\u0001\u001b[33m\u0002\u0001\u001b[00m\u0002 ')" -i ''$1
  '';

  pylsp-wrapper = pkgs.stdenvNoCC.mkDerivation {
    name = "pylsp-wrapper";
    buildInputs = [ pkgs.makeWrapper ];

    buildCommand = ''
      mkdir -p $out/bin
      makeWrapper ${python-lsp-server}/bin/pylsp $out/bin/pylsp \
        --unset PYTHONPATH
    '';
  };

in
{
  id = "python-${community-version}";
  name = "Python ${community-version} Tools";

  packages = [
    python3-wrapper
    pip
    poetry
    run-prybar
    pylsp-wrapper
  ];

  replit.runners.python = {
    name = "Python ${community-version}";
    fileParam = true;
    language = "python3";
    start = "${python3-wrapper}/bin/python3 $file";
  };

  replit.runners.python-prybar = {
    name = "Prybar for Python ${community-version}";
    fileParam = true;
    language = "python3";
    start = "${run-prybar}/bin/run-prybar $file";
    interpreter = true;
  };

  replit.debuggers.dapPython = {
    name = "DAP Python";
    language = "python3";
    start = "${dapPython}/bin/dap-python $file";
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

  replit.languageServers.python-lsp-server = {
    name = "python-lsp-server";
    language = "python3";
    start = "${pylsp-wrapper}/bin/pylsp";
    configuration.pylsp.plugins.jedi.extra_paths = [ "${pylibs-dir}/${python.sitePackages}" ];
  };

  replit.packagers.upmPython = {
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

  replit.env =
    let userbase = "$REPL_HOME/${pylibs-dir}";
    in {
      PYTHONPATH = "${userbase}/${python.sitePackages}";
      PIP_CONFIG_FILE = pip-config.outPath;
      POETRY_CONFIG_DIR = poetry-config.outPath;
      POETRY_VIRTUALENVS_CREATE = "0";
      PYTHONUSERBASE = userbase;
    };
}
