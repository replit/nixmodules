{ pkgs, pkgs-unstable }:
let
  mkModule = path: pkgs.callPackage ../moduleit/entrypoint.nix {
    configPath = path;
    inherit pkgs-unstable;
  };
  mkDeploymentModule = path: pkgs.callPackage ../moduleit/entrypoint.nix {
    configPath = path;
    inherit pkgs-unstable;
    deployment = true;
  };

  modulesList = [
    (import ./python {
      python = pkgs.python38Full;
      pypkgs = pkgs.python38Packages;
    })
    (import ./python {
      python = pkgs.python310Full;
      pypkgs = pkgs.python310Packages;
    })
    (import ./python {
      python = pkgs.python311Full;
      pypkgs = pkgs.python311Packages;
    })
    (import ./python-with-prybar)

    (import ./pyright-extended)

    (import ./nodejs {
      nodejs = pkgs.nodejs-18_x;
    })
    (import ./nodejs {
      nodejs = pkgs.nodejs_20;
    })
    (import ./nodejs-with-prybar)

    (import ./go)
    (import ./rust)
    (import ./swift)
    (import ./bun)
    (import ./c)
    (import ./cpp)
    (import ./dart)
    (import ./gcloud)
    (import ./clojure)
    (import ./dotnet)
    (import ./haskell)
    (import ./java)
    (import ./lua)
    (import ./nix)
    (import ./php)
    (import ./qbasic)
    (import ./R)
    (import ./ruby)
    (import ./svelte-kit)
    (import ./web)
  ];

  modules = builtins.listToAttrs (
    map
      (moduleInput:
        let
          module = mkModule moduleInput;
        in
        {
          name = get-module-id module;
          value = module;
        }
      )
      modulesList
  );

  deploymentModules = builtins.listToAttrs (
    map
      (moduleInput:
        let
          module = mkDeploymentModule moduleInput;
        in
        {
          name = get-deployment-module-id module;
          value = module;
        }
      )
      modulesList
  );

  get-module-id = module:
    let
      match = builtins.match "^\/nix\/store\/([^-]+)-replit-module-(.+)$" module.outPath;
    in
    builtins.elemAt match 1;

  get-deployment-module-id = module:
    let
      match = builtins.match "^\/nix\/store\/([^-]+)-replit-deployment-module-(.+)$" module.outPath;
    in
    builtins.elemAt match 1;
in
{ inherit modules deploymentModules; }
