{ pkgs ? import <nixpkgs> { }
, configPath
}:

(pkgs.lib.evalModules {
  modules = [
    configPath
    (import ./module-definition.nix)
  ];
  specialArgs = {
    inherit pkgs;
    modulesPath = builtins.toString ./.;
  };
}).config.replit.buildModule
