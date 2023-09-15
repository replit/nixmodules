{ runPackageJsonScript, runFileScript }:

{ config, lib, pkgs-unstable, ... }:

let
  bun = pkgs-unstable.callPackage ../../bun { };

  script = pkgs-unstable.writeScript "package-json-runner" ''
    #!${bun}/bin/bun
    
    ${builtins.readFile ./script.js}
  '';
in

{
  replit.runners."package.json" = {
    name = "package.json";
    start = "${script} --run-script ${runFileScript} --run-package-json-script ${runPackageJsonScript}";
    optionalFileParam = true;
  };
}
