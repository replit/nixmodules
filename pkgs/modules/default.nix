{ pkgs, pkgs-unstable, pkgs-legacy } @ all-pkgs:
let
  mkModule = path: pkgs.callPackage ../moduleit/entrypoint.nix {
    configPath = path;
    inherit pkgs-unstable;
  };

  mkLegacyModule = path: pkgs-legacy.callPackage ../moduleit/entrypoint.nix {
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

    (mkModule (import ./cpp {
      clang = pkgs.clang_12;
    }))
    (mkModule (import ./cpp {
      clang = pkgs.clang_14;
    }))

    (mkModule (import ./dotnet {
      dotnet = pkgs.dotnet_7;
    }))
    (mkLegacyModule (import ./dotnet {
      dotnet = pkgs.dotnet_6;
    }))

    (mkModule (import ./dart {
      inherit (pkgs) dart;
    }))
    (mkModule (import ./dart {
      dart = pkgs.dart.overrideAttrs (attrs: rec {
        version = "2.10.5";
        src = pkgs.fetchurl {
          url = "https://storage.googleapis.com/dart-archive/channels/stable/release/${version}/sdk/dartsdk-linux-x64-release.zip";
          sha256 = "sha256-UDeiwP1jGvwed+jvhv4atgQg2BDKtnrIb0F52feoZtU=";
        };
      });
    }))

    (mkModule (import ./go {
      inherit (pkgs) go;
    }))
    (mkModule (import ./go {
      go = pkgs.go_1_17;
    }))

    (mkModule ./apl)
    (mkModule ./bash)
    (mkModule ./basic)
    (mkModule ./brainfuck)
    (mkModule ./bun)
    (mkModule ./clojure)
    (mkLegacyModule ./clojure)
    (mkLegacyModule ./crystal)
    (mkLegacyModule ./deno)
    (mkModule ./elisp)
    (mkLegacyModule ./elixir)
    (mkLegacyModule ./emoticon)
    (mkLegacyModule ./erlang)
    (mkLegacyModule ./forth)
    (mkModule ./gcloud)
    (mkModule ./haskell)
    (mkModule ./java)
    (mkLegacyModule ./julia)
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
