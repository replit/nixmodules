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
      displayVersion = "1.0.23";
    }
    {
      moduleId = "dart-2.18";
      commit = "c48c43c6c698223ed3ce2abc5a2d708735a77d5b";
      displayVersion = "2.18.0";
    }
    {
      moduleId = "dart-3.0";
      commit = "0b7a60667d2c29f2686211e952924a9693916a20";
      displayVersion = "3.2.4";
    }
    {
      moduleId = "dart-3.1";
      commit = "3b22c787fd20b13fe5afb868589c574068303b5e";
      displayVersion = "3.2.4";
    }
    {
      moduleId = "dart-3.2";
      commit = "9e3a33995f94a52e61ae962777e9bcbe6d75885e";
      displayVersion = "3.2.4";
    }
    {
      moduleId = "dart-3.3";
      commit = "54ea6c58e71bf278c3ce8824de3dbbaa49662be4";
    }
    {
      moduleId = "go-1.19";
      commit = "c48c43c6c698223ed3ce2abc5a2d708735a77d5b";
      displayVersion = "1.19.3";
    }
    {
      moduleId = "go-1.20";
      commit = "b5aa5df636c4cd8cd1aea251e8dea4fc0aa51781";
      displayVersion = "1.20.4";
    }
    {
      moduleId = "haskell-ghc9.0";
      commit = "c48c43c6c698223ed3ce2abc5a2d708735a77d5b";
      displayVersion = "9.0.2";
    }
    {
      moduleId = "haskell-ghc9.2";
      commit = "4c6f2315da24b84bd5e9dfedb952e41677724aaa";
      displayVersion = "9.2.8";
    }
    {
      moduleId = "haskell-ghc9.4";
      commit = "4d6f7cd9fd685a3319ac7b6e3fc0789b430d6289";
      displayVersion = "9.4.8";
    }
    {
      moduleId = "elixir-1_15";
      commit = "4d6f7cd9fd685a3319ac7b6e3fc0789b430d6289";
      displayVersion = "1.15.7";
    }
    {
      moduleId = "nodejs-14";
      commit = "f4cd419a646009297c049a2f1eec434381e08f13";
      displayVersion = "14.21.1";
    }
    {
      moduleId = "nodejs-16";
      commit = "f4cd419a646009297c049a2f1eec434381e08f13";
      displayVersion = "16.18.1";
    }
    {
      moduleId = "nodejs-19";
      commit = "f4cd419a646009297c049a2f1eec434381e08f13";
      displayVersion = "19.1.0";
    }
    {
      moduleId = "php-8.1";
      commit = "0b7a60667d2c29f2686211e952924a9693916a20";
      displayVersion = "8.1.20";
    }
    {
      moduleId = "r-4.2";
      commit = "1e1bb663068482cdb7c04bf585daed00205c0140";
      displayVersion = "4.2.3";
    }
    {
      moduleId = "swift-5.6";
      commit = "c48c43c6c698223ed3ce2abc5a2d708735a77d5b";
      displayVersion = "5.6.2";
    }
    {
      moduleId = "vue-node-18";
      commit = "3ea4bcdbdc3c5e3c09b37b07edcd61781f9695f7";
      displayVersion = "18.18.2";
    }
    {
      moduleId = "zig-0.11";
      commit = "15426ef79793bf7c424eb40865d507eacfdd44e6";
      displayVersion = "0.11.0";
    }
  ];

  moduleFromHistory = { displayVersion, moduleId, commit, deployment ? false }:
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
        ${pkgs.jq}/bin/jq --arg displayVersion "${displayVersion}" '.displayVersion |= $displayVersion' < ${module} > $out
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
          inherit (module) moduleId commit;
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
