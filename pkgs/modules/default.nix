{ pkgs, pkgs-unstable } @ all-pkgs:
let
  mkModule = path: pkgs.callPackage ../moduleit/entrypoint.nix {
    configPath = path;
    inherit pkgs-unstable;
  };

  modulesList = [
    (mkModule ./python/python2.nix)
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
    (mkModule ./pyright-extended)

    (mkModule (import ./nodejs {
      nodejs = pkgs.nodejs-18_x;
    }))
    (mkModule (import ./nodejs {
      nodejs = pkgs.nodejs_20;
    }))

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
    (mkModule ./php)
    (mkModule ./qbasic)
    (mkModule ./R)
    (mkModule ./ruby)
    (mkModule ./svelte-kit)
    (mkModule ./web)
  ] ++ builtins.map mkModule (import ./migrate2nix all-pkgs);

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
