{ pkgs }:
let
  mkModule = path: pkgs.callPackage ../moduleit/entrypoint.nix {
    configPath = path;
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
    map (module:
      let info = get-module-info module;
      in {
        name = info.id;
        value = info;
      }) modulesList
  );

  get-module-info = module:
    let inputs = (builtins.fromJSON (builtins.unsafeDiscardStringContext module.text));
    in {
      inherit (inputs) id name description;
      inherit module;
    };
in
  modules