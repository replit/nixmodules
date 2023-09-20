{ runPackageJsonScript, runFileScript }:

{ config, lib, pkgs-unstable, ... }:

let
  bun = pkgs-unstable.callPackage ../../bun { };

  script = pkgs-unstable.writeScriptBin "package-json-runner" ''
    #!${bun}/bin/bun

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
