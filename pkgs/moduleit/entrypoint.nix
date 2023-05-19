{ pkgs ? import <nixpkgs> { }
, configPath
, pkgs-unstable
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
