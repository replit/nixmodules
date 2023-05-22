{ pkgs ? import <nixpkgs> { }
, configPath
, self
}:
(pkgs.lib.evalModules {
  modules = [
    configPath
    (import ./module-definition.nix)
  ];
  specialArgs = {
    inherit pkgs self;
    modulesPath = builtins.toString ./.;
  };
}).config.replit.buildModule
