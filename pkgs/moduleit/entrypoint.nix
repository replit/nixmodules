{ pkgs ? import <nixpkgs-unstable> { }
, pkgs-23_05 ? import <nixpkgs-stable-23_05> { }
, pkgs-24_11 ? import <nixpkgs-stable-24_11> { }
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
      inherit pkgs pkgs-23_05 pkgs-24_11;
      pkgs-unstable = pkgs;
      modulesPath = builtins.toString ./.;
    };
  });
in
if deployment then
  module.config.replit.buildDeploymentModule
else
  module.config.replit.buildModule
