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
in
pkgs.lib.lazyDerivation {
  derivation = result;
  passthru = {
    moduleId = module.config.id;
  } // pkgs.lib.optionalAttrs (!deployment) {
    shellPackage = pkgs.callPackage ./shell-package.nix {
      name = "replit-shell-${module.config.id}";
      moduleId = module.config.id;
      module = result;
      packages = module.config.replit.packages ++ module.config.replit.dev.packages;
      env = result.moduleConfig.env;
    };
  };
}
