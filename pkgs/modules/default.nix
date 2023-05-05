{ pkgs }:
let
  mkModule = path: pkgs.callPackage ../moduleit/entrypoint.nix {
    configPath = path;
  };
  
  modulesList = [
    (mkModule ./go)
    (mkModule ./rust)
    (mkModule ./swift)
  ];

  modules = builtins.listToAttrs (
    map (module: { name = get-module-id module; value = module; }) modulesList
  );

  get-module-id = module:
    let
      match = builtins.match "^\/nix\/store\/([^-]+)-replit-module-(.+)$" module.outPath;
    in
      builtins.elemAt match 1;
in
  modules