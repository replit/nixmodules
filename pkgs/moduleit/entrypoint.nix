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
    replit-prompt = "\\u0001\\u001b[33m\\u0002\\u0001\\u001b[00m\\u0002 ";
  };
}).config.replit.buildModule
