{ runPackageJsonScript, runFileScript }:

{ config, lib, pkgs, ... }:

let
  script = pkgs.writeScriptBin "package-json-runner" ''
    #! ${pkgs.nodejs}/bin/node

    ${builtins.readFile ./script.js}
  '';
in

{
  packages = [
    script
  ];

  replit.runners."package.json" = {
    name = "package.json";
    start = "${script}/bin/package-json-runner --run-script ${runFileScript} --run-package-json-script ${runPackageJsonScript}";
    optionalFileParam = true;
  };
}
