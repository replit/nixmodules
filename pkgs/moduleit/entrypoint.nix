{ pkgs ? import <nixpkgs> { }
, configPath
}:
let pruneVersion = version:
  let
    parts = pkgs.lib.strings.splitString "." version;
    major = builtins.elemAt parts 0;
    minor = builtins.elemAt parts 1;
  in
    "${major}.${minor}";
in   
(pkgs.lib.evalModules {
  modules = [
    configPath
    (import ./module-definition.nix)
  ];
  specialArgs = {
    inherit pkgs;
    modulesPath = builtins.toString ./.;
    inherit pruneVersion;
  };
}).config.replit.buildModule
