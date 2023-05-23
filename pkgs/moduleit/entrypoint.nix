{ pkgs ? import <nixpkgs> { }
, pkgs-unstable ? import <nixpkgs-unstable> { }
, configPath
}:
(pkgs.lib.evalModules {
  modules = [
    configPath
    (import ./module-definition.nix)
  ];
  specialArgs = {
    inherit pkgs;
    inherit pkgs-unstable;
    modulesPath = builtins.toString ./.;
  };
}).config.replit.buildModule
