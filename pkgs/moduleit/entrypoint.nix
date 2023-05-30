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
    inherit pkgs pkgs-unstable;
    modulesPath = builtins.toString ./.;
  };
}).config.replit.buildModule
