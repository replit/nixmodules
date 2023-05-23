{ pkgs ? import <nixpkgs> { }
, pkgs-unstable ? import <nixpkgs-unstable> { }
, configPath
, self
}:
(pkgs.lib.evalModules {
  modules = [
    configPath
    (import ./module-definition.nix)
  ];
  specialArgs = {
    inherit pkgs pkgs-unstable self;
    modulesPath = builtins.toString ./.;
  };
}).config.replit.buildModule
