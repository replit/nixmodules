{ python, pypkgs }:
{ pkgs, pruneVersion, ... }:
let
  community-version = pruneVersion python.version;

  pip = pkgs.callPackage ../../pip {
    inherit pypkgs;
  };

  prybar-python = pkgs.prybar.prybar-python310;

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

in
{
  id = "python";
  name = "Python Tools";
  inherit community-version;
  version = "1.0";

  packages = [
    python3-wrapper
    pip
    poetry
    run-prybar
    python-lsp-server
  ];

  replit.runners.python = {
    name = "Python ${community-version}";
    fileParam = true;
    language = "python3";
    start = "${python3-wrapper}/bin/python3 $file";
  };

  replit.runners.python-prybar = {
    name = "Prybar for Python 3.10";
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
    start = "${python-lsp-server}/bin/pylsp";
  };

  replit.packagers.upmPython = {
    name = "Python";
    language = "python3";
    ignoredPackages = [ "unit_tests" ];
    ignoredPaths = [ ".pythonlibs" ];
    features = {
      packageSearch = true;
      guessImports = true;
      enabledForHosting = false;
    };
  };

  replit.env =
    let userbase = "$HOME/$REPL_SLUG/.pythonlibs";
    in {
      PYTHONPATH = "${userbase}/${python.sitePackages}";
      PIP_CONFIG_FILE = pip-config.outPath;
      POETRY_CONFIG_DIR = poetry-config.outPath;
      POETRY_VIRTUALENVS_CREATE = "0";
      PYTHONUSERBASE = userbase;
    };
}
