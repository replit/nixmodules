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

    (mkModule (import ./c {
      clang = pkgs.clang_12;
    }))
    (mkModule (import ./c {
      clang = pkgs.clang_14;
    }))

    (mkModule ./apl)
    (mkModule ./bash)
    (mkModule ./basic)
    (mkModule ./brainfuck)
    (mkModule ./bun)
    (mkModule ./clojure)
    (mkModule ./cpp)
    (mkModule ./dart)
    (mkModule ./dotnet)
    (mkModule ./gcloud)
    (mkModule ./go)
    (mkModule ./haskell)
    (mkModule ./java)
    (mkModule ./lua)
    (mkModule ./php)
    (mkModule ./qbasic)
    (mkModule ./R)
    (mkModule ./ruby)
    (mkModule ./rust)
    (mkModule ./svelte-kit)
    (mkModule ./swift)
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
