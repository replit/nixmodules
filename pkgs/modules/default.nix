{ pkgs, pkgs-unstable }:
let
  mkModule = path: pkgs.callPackage ../moduleit/entrypoint.nix {
    configPath = path;
    inherit pkgs-unstable;
  };

  modulesList = [
    (mkModule (import ./python {
      python = pkgs.python38Full;
      pypkgs = pkgs.python38Packages;
    }))
    (mkModule (import ./python {
      python = pkgs.python310Full;
      pypkgs = pkgs.python310Packages;
    }))
    (mkModule (import ./python {
      python = pkgs.python311Full;
      pypkgs = pkgs.python311Packages;
    }))
    (pkgs-unstable.callPackage ../moduleit/entrypoint.nix {
      configPath = (import ./python {
        python = pkgs-unstable.python312;
        pypkgs = pkgs-unstable.python312Packages;
      });
    })
    (mkModule ./python-with-prybar)
    (mkModule ./pyright-extended)

    (mkModule (import ./nodejs {
      nodejs = pkgs.nodejs-18_x;
    }))
    (mkModule (import ./nodejs {
      nodejs = pkgs.nodejs_20;
    }))
    (mkModule ./nodejs-with-prybar)

    (mkModule ./go)
    (mkModule ./rust)
    (mkModule ./swift)
    (mkModule ./bun)
    (mkModule ./c)
    (mkModule ./cpp)
    (mkModule ./dart)
    (mkModule ./gcloud)
    (mkModule ./clojure)
    (mkModule ./dotnet)
    (mkModule ./haskell)
    (mkModule ./java)
    (mkModule ./lua)
    (mkModule ./nix)
    (mkModule ./php)
    (mkModule ./qbasic)
    (mkModule ./R)
    (mkModule ./ruby)
    (mkModule ./svelte-kit)
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
