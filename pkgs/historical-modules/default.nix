{ pkgs }:
with builtins;
let
  # This is a list of modules we no longer actively maintain
  # but still provide to users via historical versions of this repo.
  # It can happen when we upgrade a Nix channel, which changes the
  # version of the software, so the older version is no longer in the
  # channel. Technically it is feasible to maintain older versions even
  # in the latest channel, but it's more work.
  historicalModulesList = [
    {
      moduleId = "bun-1.0";
      commit = "fdbd39619614e07d1ff44cfe20de2ad56eb8a40f";
      overrides = {
        # /nix/store/cvz36f39793v9l361ibfxznjjmk4jpd6-replit-module-bun-1.0
        # .runners["package.json"].displayVersion = "1.0.23";
        displayVersion = "1.0.23";
      };
    }
    {
      moduleId = "clojure-1.11";
      commit = "4327245815e8500233ed3af1cbb674bd147f673b";
      overrides = {
        displayVersion = "1.11";
      };
    }
    {
      moduleId = "dart-2.18";
      commit = "c48c43c6c698223ed3ce2abc5a2d708735a77d5b";
      overrides = {
        # /nix/store/05i6y0nwn8zgm6250my14xbcialzak9b-replit-module-dart-2.18
        # .runners.dart.displayVersion = "2.18.0";
        displayVersion = "2";
      };
    }
    {
      moduleId = "dart-3.0";
      commit = "0b7a60667d2c29f2686211e952924a9693916a20";
      overrides = {
        # /nix/store/0wr2lk1h8vqzs38pfwiil6cf6s5mn54j-replit-module-dart-3.2
        # .runners.dart.displayVersion = "3.2.4";
        displayVersion = "3";
      };
    }
    {
      moduleId = "dart-3.1";
      commit = "3b22c787fd20b13fe5afb868589c574068303b5e";
      # displayVersion = "3.2.4";
      overrides = {
        displayVersion = "3";
      };
    }
    {
      moduleId = "dart-3.2";
      commit = "9e3a33995f94a52e61ae962777e9bcbe6d75885e";
      # displayVersion = "3.2.4";
      overrides = {
        displayVersion = "3";
      };
    }
    {
      moduleId = "dart-3.3";
      commit = "54ea6c58e71bf278c3ce8824de3dbbaa49662be4";
      overrides = {
        # /nix/store/ampsihgvns831ig1w0warbpq1pyj2cg0-replit-module-dart-3.3
        # .runners.dart.displayVersion = "3.3.4";
        displayVersion = "3";
      };
    }
    {
      moduleId = "deno-1";
      commit = "4327245815e8500233ed3af1cbb674bd147f673b";
      overrides = {
        displayVersion = "1";
      };
    }
    {
      moduleId = "docker";
      commit = "185d7dc7645178f92fd891f9efa20b3343c0f20d";
      overrides = {
        displayVersion = "1";
        internal = true;
      };
    }
    {
      moduleId = "dotnet-7.0";
      commit = "4327245815e8500233ed3af1cbb674bd147f673b";
      overrides = {
        displayVersion = "7.0";
      };
    }
    {
      moduleId = "go-1.19";
      commit = "c48c43c6c698223ed3ce2abc5a2d708735a77d5b";
      overrides = {
        # /nix/store/7icmam9gmbfas0zbpm53f3ilw79kx0rj-replit-module-go-1.19
        # .runners["go-run"].displayVersion = "1.19.3";
        displayVersion = "1.19";
      };
    }
    {
      moduleId = "go-1.20";
      commit = "b5aa5df636c4cd8cd1aea251e8dea4fc0aa51781";
      overrides = {
        # /nix/store/q6j9za8smkdbnlybg63qq5lmj7zbambr-replit-module-go-1.20
        # .runners["go-run"].displayVersion = "1.20.4";
        displayVersion = "1.20";
      };
    }
    {
      moduleId = "go-1.21";
      commit = "76ae6535d7d60e767fe9d54902400229ca0b9448";
      overrides = {
        # /nix/store/...-replit-module-go-1.21
        # .runners["go-run"].displayVersion = "1...";
        displayVersion = "1.21";
      };
    }
    {
      moduleId = "haskell-ghc9.0";
      commit = "c48c43c6c698223ed3ce2abc5a2d708735a77d5b";
      overrides = {
        # /nix/store/h6hp6fd07dr8q9dhlz45nrs17wp2kmp4-replit-module-haskell-ghc9.0
        # .runners.runghc.displayVersion = "9.0.2";
        displayVersion = "9";
      };
    }
    {
      moduleId = "haskell-ghc9.2";
      commit = "4c6f2315da24b84bd5e9dfedb952e41677724aaa";
      overrides = {
        # /nix/store/1r94iizf604jasg72f239fw0if4ldmd5-replit-module-haskell-ghc9.2
        # .runners.runghc.displayVersion = "9.2.8";
        displayVersion = "9";
      };
    }
    {
      moduleId = "haskell-ghc9.4";
      commit = "4d6f7cd9fd685a3319ac7b6e3fc0789b430d6289";
      overrides = {
        # /nix/store/kkaxlri9s0bb7jydb1kpqzi2sjkf4rmj-replit-module-haskell-ghc9.4
        # .runners.runghc.displayVersion = "9.4.8";
        displayVersion = "9";
      };
    }
    {
      moduleId = "elixir-1_15";
      commit = "4d6f7cd9fd685a3319ac7b6e3fc0789b430d6289";
      overrides = {
        # /nix/store/8nggvav01q7f1094m485nnd32094j522-replit-module-elixir-1_15
        # .runners.elixir.displayVersion = "1.15.7";
        displayVersion = "1";
      };
    }
    {
      moduleId = "nodejs-14";
      commit = "f4cd419a646009297c049a2f1eec434381e08f13";
      overrides = {
        name = "Node.js Tools";
        displayVersion = "14";
        runners = {
          nodeJS = {
            displayVersion = "14.21.1";
          };
        };
      };
    }
    {
      moduleId = "nodejs-16";
      commit = "f4cd419a646009297c049a2f1eec434381e08f13";
      overrides = {
        name = "Node.js Tools";
        displayVersion = "16";
        runners = {
          nodeJS = {
            displayVersion = "16.18.1";
          };
        };
      };
    }
    {
      moduleId = "nodejs-19";
      commit = "f4cd419a646009297c049a2f1eec434381e08f13";
      overrides = {
        name = "Node.js Tools";
        displayVersion = "19";
        runners = {
          nodeJS = {
            displayVersion = "19.1.0";
          };
        };
      };
    }
    {
      moduleId = "php-8.1";
      commit = "0b7a60667d2c29f2686211e952924a9693916a20";
      overrides = {
        # /nix/store/xc89rlwnmg5vh66hvrv1saq6md6kp1g5-replit-module-php-8.1
        # .runners.php.displayVersion = "8.1.20";
        displayVersion = "8";
      };
    }
    {
      moduleId = "php-8.2";
      commit = "4327245815e8500233ed3af1cbb674bd147f673b";
      overrides = {
        displayVersion = "8.2";
      };
    }
    {
      moduleId = "python-3.8";
      commit = "76ae6535d7d60e767fe9d54902400229ca0b9448";
      overrides = {
        displayVersion = "3.8";
      };
    }
    {
      moduleId = "r-4.2";
      commit = "1e1bb663068482cdb7c04bf585daed00205c0140";
      overrides = {
        # /nix/store/knizlzgmqgm488llvxxaai6kjb17mhm2-replit-module-r-4.2
        # .runners.r.displayVersion = "4.2.3";
        displayVersion = "4";
      };
    }
    {
      moduleId = "swift-5.6";
      commit = "c48c43c6c698223ed3ce2abc5a2d708735a77d5b";
      overrides = {
        # /nix/store/f96l8blsvpx1dbgnxw2x611hhzbm199l-replit-module-swift-5.6
        # .runners.swift.displayVersion = "5.6.2";
        displayVersion = "5";
      };
    }
    {
      moduleId = "zig-0.11";
      commit = "15426ef79793bf7c424eb40865d507eacfdd44e6";
      overrides = {
        # /nix/store/65v1j76svgdi8bj3sxx5hfshbvdyissl-replit-module-zig-0.11
        # .runners["zig-build-run"].displayVersion = "0.11.0";
        displayVersion = "0";
      };
    }
  ];

  moduleFromHistory = { moduleId, commit, deployment ? false, overrides }:
    let
      flake = getFlake "github:replit/nixmodules/${commit}";
      module =
        if deployment then
          (flake.deploymentModules or flake.modules).${moduleId}
        else
          flake.modules.${moduleId};
    in
    pkgs.stdenvNoCC.mkDerivation {
      name = "replit-module-${moduleId}";
      buildCommand = ''
        set -x
        ${pkgs.jq}/bin/jq --argjson overrides '${builtins.toJSON(overrides)}' '. * $overrides' < ${module} > $out
      '';
    };

  modules = foldl'
    (acc: module:
      acc // ({
        ${module.moduleId} = moduleFromHistory module;
      })
    )
    { }
    historicalModulesList;

  deploymentModules = foldl'
    (acc: module:
      acc // ({
        ${module.moduleId} = moduleFromHistory {
          inherit (module) moduleId commit overrides;
          deployment = true;
        };
      })
    )
    { }
    historicalModulesList;

in
{
  inherit modules deploymentModules;
}
