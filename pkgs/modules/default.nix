{ pkgs, pkgs-unstable, self }:
let
  mkModule = path: pkgs.callPackage ../moduleit/entrypoint.nix {
    configPath = path;
    inherit pkgs-unstable;
    inherit self;
  };
  
  modulesList = [
    (mkModule (import ./python {
      python = pkgs.python310Full;
      pypkgs = pkgs.python310Packages;
    }))
    (mkModule (import ./nodejs {
      nodejs = pkgs.nodejs-14_x;
    }))
    (mkModule (import ./nodejs {
      nodejs = pkgs.nodejs-19_x;
    }))
    (mkModule (import ./nodejs {
      nodejs = pkgs.nodejs-18_x;
    }))
    (mkModule (import ./nodejs {
      nodejs = pkgs.nodejs-16_x;
    }))
    (mkModule ./go)
    (mkModule ./rust)
    (mkModule ./swift)
    (mkModule ./bun)
    (mkModule ./c)
    (mkModule ./cpp)
    (mkModule ./dart)
    (mkModule ./clojure)
    (mkModule ./dotnet)
    (mkModule ./haskell)
    (mkModule ./java)
    (mkModule ./lua)
    (mkModule ./php)
    (mkModule ./qbasic)
    (mkModule ./R)
    (mkModule ./ruby)
    (mkModule ./web)
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