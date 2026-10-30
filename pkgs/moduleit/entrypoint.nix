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
  result =
    if deployment then module.config.replit.buildDeploymentModule
    else module.config.replit.buildModule;
  packages = module.config.replit.packages
    ++ pkgs.lib.optionals (!deployment) module.config.replit.dev.packages;
in
pkgs.lib.lazyDerivation {
  derivation = result;
  passthru = {
    moduleId = module.config.id;
    moduleConfig = result.moduleConfig;
    runtimePackages = packages;
    shellPackage = pkgs.callPackage ./shell-package.nix {
      name = "replit-${if deployment then "deployment-" else ""}shell-${module.config.id}";
      inherit packages;
      env = result.moduleConfig.env;
      passthru.module = result;
    };
  };
}
