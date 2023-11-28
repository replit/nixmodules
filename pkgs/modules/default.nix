{ pkgs }:
let
  mkModule = path: pkgs.callPackage ../moduleit/entrypoint.nix {
    configPath = path;
  };
  mkDeploymentModule = path: pkgs.callPackage ../moduleit/entrypoint.nix {
    configPath = path;
    deployment = true;
  };

  modulesList = [
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

    (import ./go {
      inherit (pkgs) go gopls;
    })
    (import ./go {
      go = pkgs.go_1_21;
      gopls = pkgs.gopls.override {
        buildGoModule = pkgs.buildGo121Module;
      };
    })

    (import ./rust)
    # TODO: re-enable when building swift is fixed in nixpkgs
    # (import ./swift)
    (import ./bun)
    (import ./c)
    (import ./cpp)
    (import ./dart)
    (import ./docker)
    (import ./gcloud)
    (import ./clojure)
    (import ./dotnet)
    (import ./haskell)
    # TODO: re-enable when java-debug and java-language-server are fixed, other unknowns
    # (import ./java)
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
