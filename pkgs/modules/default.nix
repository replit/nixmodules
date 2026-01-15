{ pkgs
, pkgs-23_05
, pkgs-24_11
, pkgs-25_05
, pkgs-master
, pkgs-staging
, ...
}:
with builtins;
let
  mkModule =
    path:
    pkgs.callPackage ../moduleit/entrypoint.nix {
      configPath = path;
      inherit pkgs-23_05 pkgs-24_11;
    };
  mkDeploymentModule =
    path:
    pkgs.callPackage ../moduleit/entrypoint.nix {
      configPath = path;
      inherit pkgs-23_05 pkgs-24_11;
      deployment = true;
    };
  apply-upgrade-map = import ../upgrade-map;
  historical = pkgs.callPackage ../historical-modules { };

  modulesList = [
    (import ./python {
      python = pkgs-24_11.python39Full;
      pypkgs = pkgs-24_11.python39Packages;
    })
    (import ./python {
      python = pkgs.python310;
      pypkgs = pkgs.python310Packages;
    })
    (import ./python {
      python = pkgs.python311;
      pypkgs = pkgs.python311Packages;
    })
    (import ./python {
      python = pkgs.python312;
      pypkgs = pkgs.python312Packages;
    })
    (import ./python-base {
      python = pkgs.python311;
      pypkgs = pkgs.python311Packages;
    })
    (import ./python-base {
      python = pkgs.python312;
      pypkgs = pkgs.python312Packages;
    })
    (import ./python-base {
      python = pkgs.python313;
      pypkgs = pkgs.python313Packages;
    })
    (import ./pyright-extended {
      nodejs = pkgs-24_11.nodejs-18_x;
    })
    (import ./pyright)
    (import ./ruff)

    (import ./nodejs {
      nodejs = pkgs-24_11.nodejs-18_x;
    })
    (import ./nodejs {
      nodejs = pkgs-master.nodejs_20;
    })
    (import ./nodejs {
      nodejs = pkgs-master.nodejs_22;
    })
    (import ./nodejs {
      nodejs = pkgs-24_11.nodejs_23;
    })
    (import ./nodejs {
      nodejs = pkgs-staging.nodejs_24;
    })
    (import ./go {
      go = pkgs.go_1_25;
      gopls = pkgs.gopls.override {
        buildGoLatestModule = pkgs.buildGo125Module;
      };
    })

    (import ./rust "stable")
    (import ./rust "latest")

    (import ./angular {
      nodejs = pkgs.nodejs_20;
    })
    (import ./angular {
      nodejs = pkgs.nodejs_24;
    })
    (import ./bash)
    (import ./bun)
    (import ./c)
    (import ./cpp)
    (import ./dart)
    (import ./deno)
    # (import ./docker)
    (import ./elixir)
    (import ./gcloud)
    (import ./clojure)
    (import ./dotnet {
      dotnet = pkgs.dotnet-sdk_8;
    })
    (import ./dotnet {
      dotnet = pkgs.dotnet-sdk_9;
    })
    (import ./dotnet {
      dotnet = pkgs.dotnet-sdk_10;
    })
    (import ./haskell)
    (import ./java)
    (import ./lua)
    (import ./nix)
    (import ./php)
    (import ./postgresql {
      postgresql = pkgs-25_05.postgresql_16;
    })
    (import ./postgresql {
      postgresql = pkgs-25_05.postgresql_17;
    })
    (import ./qbasic)
    (import ./R)
    (import ./replit)
    (import ./ruby {
      ruby = pkgs.ruby_4_0;
      rubyPackages = pkgs.rubyPackages_4_0;
    })
    (
      # pinning ruby to specific version to avoid breaking gems with built .so's
      # that are installed into the Rails template. TODO: have a way of detecting
      # an upgrade and re-installing gems.
      let
        ruby_3_2_2 = pkgs.mkRuby {
          version = pkgs.mkRubyVersion "3" "2" "2" "";
          hash = "sha256-lsV1WIcaZ0jeW8nydOk/S1qtBs2PN776Do2U57ikI7w=";
          cargoHash = "sha256-CMVx5/+ugDNEuLAvyPN0nGHwQw6RXyfRsMO9I+kyZpk=";
        };
        rubyPackages_3_2_2 = pkgs.lib.attrsets.recurseIntoAttrs ruby_3_2_2.gems;
      in
      (import ./ruby {
        ruby = ruby_3_2_2;
        rubyPackages = rubyPackages_3_2_2;
      })
    )
    (import ./swift)
    (import ./svelte-kit)
    (import ./vue {
      nodejs = pkgs.nodejs_20;
    })
    (import ./vue {
      nodejs = pkgs-24_11.nodejs-18_x;
    })
    (import ./web)
    (import ./hermit)
    (import ./typescript-language-server {
      nodepkgs = pkgs.nodePackages;
    })
    (import ./replit-rtld-loader)
  ];

  activeModules = listToAttrs (
    map
      (
        moduleInput:
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

  modules = apply-upgrade-map (activeModules // historical.modules);

  activeDeploymentModules = listToAttrs (
    map
      (
        moduleInput:
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

  deploymentModules = apply-upgrade-map (activeDeploymentModules // historical.deploymentModules);

  get-module-id =
    module:
    let
      match = builtins.match "^\/nix\/store\/([^-]+)-replit-module-(.+)$" module.outPath;
    in
    builtins.elemAt match 1;

  get-deployment-module-id =
    module:
    let
      match = builtins.match "^\/nix\/store\/([^-]+)-replit-deployment-module-(.+)$" module.outPath;
    in
    builtins.elemAt match 1;
in
{
  inherit
    modules
    activeModules
    deploymentModules
    activeDeploymentModules
    ;
}
