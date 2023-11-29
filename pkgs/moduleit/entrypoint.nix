{ pkgs ? import <nixpkgs> { }
, pkgs-unstable ? import <nixpkgs-unstable> { }
, configPath
, deployment ? false
}:
let
  module = (pkgs.lib.evalModules {
    modules = [
      configPath
      (import ./module-definition.nix)
    ];
    specialArgs = {
      inherit pkgs pkgs-unstable;
      modulesPath = builtins.toString ./.;
    };
  });
in
if deployment then
  module.config.replit.buildDeploymentModule
else
  module.config.replit.buildModule
