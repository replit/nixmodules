{ pkgs, replit-prompt, ... }:
with pkgs;

let
  electron-runner = writeShellScriptBin "basic-runner-electron" ''
    ELECTRON_BASIC_TEMPLATE=''${BASIC_TEMPLATE:-${./template}}
    exec ${electron}/bin/electron --no-sandbox $ELECTRON_BASIC_TEMPLATE $@ 2>/dev/null
  '';
in

{
  id = "basic";
  name = "Basic";

  imports = [
    (import ../typescript-language-server {
      nodepkgs = nodePackages;
    })
  ];

  packages = [
    nodejs
  ];

  replit.env = {
    npm_config_prefix = "$REPL_HOME/.config/npm/node_global";
    PATH = "$REPL_HOME/.config/npm/node_global/bin:$REPL_HOME/node_modules/.bin";
  };

  replit.runners.basic-electron = {
    name = "Basic on Electron";
    language = "basic";
    fileParam = true;
    start = "${electron-runner}/bin/basic-runner-electron --ps1 '${replit-prompt}' $file";
  };

  replit.packagers.upmNodejs = {
    name = "UPM for Node.js";
    language = "nodejs";
    features = {
      packageSearch = true;
      guessImports = true;
      enabledForHosting = false;
    };
  };
}
