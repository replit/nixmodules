{ pkgs, pkgs-unstable, lib, ... }:
let
  nodejs = pkgs.nodejs-18_x;

  nodeVersion = lib.versions.major nodejs.version;

  prybar = pkgs.prybar.prybar-nodejs;

  run-prybar = pkgs.writeShellScriptBin "run-prybar" ''
    ${prybar}/bin/prybar-nodejs -q --ps1 "''$(printf '\u0001\u001b[33m\u0002\u0001\u001b[00m\u0002 ')" -i ''$1
  '';

in
{

  id = lib.mkForce "nodejs-with-prybar-${nodeVersion}";

  name = lib.mkForce "Node.js ${nodeVersion} Tools (with Prybar)";

  imports = [
    (import ../nodejs {
      inherit nodejs;
    })
  ];

  replit.packages = [
    run-prybar
  ];

  replit.runners = lib.mkForce {
    nodeJS-prybar = {
      name = "Prybar for Node.js";
      language = "javascript";
      start = "${run-prybar}/bin/run-prybar $file";
      optionalFileParam = true;
    };
  };
}
