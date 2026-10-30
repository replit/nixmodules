{ pkgs
, pkgs-23_05
, pkgs-24_11
, pkgs-25_05
, pkgs-master
, pkgs-staging
, nodejs-22
, nodejs-24
, deno
, uv
, pkgs-php
, pkgs-docker
, pkgs-zig
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
  moduleSet = import ./module-set.nix;

  # Keep these out of activeModules, as before, without hiding their implementations.
  compatibilityModulesList = [
    (import ./docker { pkgs = pkgs-docker; })
    (import ./zig {
      zig = pkgs-zig.zigpkgs.default;
      zls = pkgs-zig.zls;
    })
  ];

  modulesList = [
    (import ./python {
      python = pkgs.python310;
      pypkgs = pkgs.python310Packages;
      inherit uv;
    })
    (import ./python {
      python = pkgs.python311;
      pypkgs = pkgs.python311Packages;
      inherit uv;
    })
    (import ./python {
      python = pkgs.python312;
      pypkgs = pkgs.python312Packages;
      inherit uv;
    })
    (import ./python-base {
      python = pkgs.python311;
      pypkgs = pkgs.python311Packages;
      inherit uv;
    })
    (import ./python-base {
      python = pkgs.python312;
      pypkgs = pkgs.python312Packages;
      inherit uv;
    })
    (import ./python-base {
      python = pkgs.python313;
      pypkgs = pkgs.python313Packages;
      inherit uv;
    })
    (import ./ty)
    (import ./ruff)

    (import ./nodejs {
      nodejs = pkgs-master.nodejs_20;
    })
    (import ./nodejs {
      nodejs = nodejs-22;
    })
    (import ./nodejs {
      nodejs = nodejs-24;
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
      nodejs = nodejs-24;
    })
    (import ./bash)
    (import ./bun {
      bun = pkgs.bun;
    })
    (import ./c)
    (import ./cpp)
    (import ./dart)
    (import ./deno { inherit deno; })
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
    (import ./php {
      php = pkgs-php.php82;
    })
    (import ./php {
      php = pkgs-php.php84;
    })
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
    (import ./svelte-kit {
      nodejs = nodejs-24;
    })
    (import ./vue {
      nodejs = pkgs.nodejs_20;
    })
    (import ./web)
    (import ./hermit)
    (import ./typescript-language-server {
      nodepkgs = pkgs.nodePackages;
    })
    (import ./replit-rtld-loader)
    (import ./graphite-cli)
    (import ./databricks-cli)
  ];

  mkModuleSet = buildModule: getId: inputs:
    moduleSet (map
      (input:
        let module = buildModule input;
        in { name = getId module; value = module; })
      inputs);

  developmentModuleSet = mkModuleSet mkModule get-module-id;
  deploymentModuleSet = mkModuleSet mkDeploymentModule get-deployment-module-id;
  allModulesList = modulesList ++ compatibilityModulesList;

  activeModules = developmentModuleSet modulesList;
  activeDeploymentModules = deploymentModuleSet modulesList;
  modules = apply-upgrade-map (developmentModuleSet allModulesList);
  deploymentModules = apply-upgrade-map (deploymentModuleSet allModulesList);

  get-module-id = module: module.moduleId;
  get-deployment-module-id = module: module.moduleId;
in
{
  inherit
    modules
    activeModules
    deploymentModules
    activeDeploymentModules
    ;
}
