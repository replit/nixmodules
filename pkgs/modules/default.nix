{ pkgs, pkgs-23_05 }:
let
  mkModule = path: pkgs.callPackage ../moduleit/entrypoint.nix {
    configPath = path;
    inherit pkgs-23_05;
  };
  mkDeploymentModule = path: pkgs.callPackage ../moduleit/entrypoint.nix {
    configPath = path;
    inherit pkgs-23_05;
    deployment = true;
  };

  modulesList = [
    (import ./python {
      python = pkgs-23_05.python38Full;
      pypkgs = pkgs-23_05.python38Packages;
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

    (import ./go {
      inherit (pkgs) go gopls;
    })
    (import ./go {
      go = pkgs.go_1_21;
      gopls = pkgs.gopls.override {
        buildGoModule = pkgs.buildGo121Module;
      };
    })

    (import ./rust "stable")
    (import ./rust "latest")

    (import ./angular)
    (import ./bash)
    (import ./bun)
    (import ./c)
    (import ./cpp)
    (import ./dart)
    (import ./deno)
    (import ./docker)
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
    (import ./replit)
    (import ./ruby {
      ruby = pkgs.ruby_3_1;
      rubyPackages = pkgs.rubyPackages_3_1;
    })
    (import ./ruby {
      ruby = pkgs.ruby_3_2;
      rubyPackages = pkgs.rubyPackages_3_2;
    })
    (import ./swift)
    (import ./svelte-kit)
    (import ./vue)
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
