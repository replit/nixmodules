{ pkgs, pkgs-23_05 }:
with builtins;
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
  apply-upgrade-map = import ../upgrade-map;
  historical = pkgs.callPackage ../historical-modules { };

  modulesList = [
    (import ./python {
      python = pkgs.python38Full;
      pypkgs = pkgs.python38Packages;
    })
    (import ./python {
      python = pkgs.python39Full;
      pypkgs = pkgs.python39Packages;
    })
    (import ./python {
      python = pkgs.python310Full;
      pypkgs = pkgs.python310Packages;
    })
    (import ./python {
      python = pkgs.python311Full;
      pypkgs = pkgs.python311Packages;
    })
    (import ./python {
      python = pkgs.python312Full;
      pypkgs = pkgs.python312Packages;
    })
    (import ./python-base {
      python = pkgs.python311Full;
      pypkgs = pkgs.python311Packages;
    })
    (import ./python-base {
      python = pkgs.python312Full;
      pypkgs = pkgs.python312Packages;
    })
    (import ./python-base {
      python = pkgs.python313Full;
      pypkgs = pkgs.python313Packages;
    })
    (import ./python-with-prybar)

    (import ./pyright-extended)

    (import ./nodejs {
      nodejs = pkgs.nodejs-18_x;
    })
    (import ./nodejs {
      nodejs = pkgs.nodejs_20;
    })
    (import ./nodejs {
      nodejs = pkgs.nodejs_22;
    })
    (import ./nodejs-with-prybar)

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
    (import ./elixir)
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
    (
      # pinning ruby to specific version to avoid breaking gems with built .so's
      # that are installed into the Rails template. TODO: have a way of detecting
      # an upgrade and re-installing gems.
      let
        ruby_3_2_2 = pkgs.mkRuby {
          version = pkgs.mkRubyVersion "3" "2" "2" "";
          hash = "sha256-lsV1WIcaZ0jeW8nydOk/S1qtBs2PN776Do2U57ikI7w=";
          cargoHash = "sha256-6du7RJo0DH+eYMOoh3L31F3aqfR5+iG1iKauSV1uNcQ=";
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
      nodejs = pkgs.nodejs_18;
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

  modules = apply-upgrade-map (activeModules // historical.modules);

  activeDeploymentModules = listToAttrs (
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

  deploymentModules = apply-upgrade-map (activeDeploymentModules // historical.deploymentModules);

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
{ inherit modules activeModules deploymentModules activeDeploymentModules; }
