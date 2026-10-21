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
      moduleId = "bun-1.1";
      commit = "1113faeb6840ba57bef3679b1f763782f5d3dd30";
      overrides = {
        displayVersion = "1.1.45";
      };
    }
    {
      moduleId = "dart-3.8";
      commit = "ae6ed05c623804560afd1cf3d80d13b6170d5c24";
      overrides = {
        displayVersion = "3.8";
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
      moduleId = "zig-0.11";
      commit = "15426ef79793bf7c424eb40865d507eacfdd44e6";
      overrides = {
        # /nix/store/65v1j76svgdi8bj3sxx5hfshbvdyissl-replit-module-zig-0.11
        # .runners["zig-build-run"].displayVersion = "0.11.0";
        displayVersion = "0";
      };
    }
    {
      moduleId = "go-1.24";
      commit = "ae6ed05c623804560afd1cf3d80d13b6170d5c24";
      overrides = {
        displayVersion = "1.24";
      };
    }
    {
      moduleId = "ruby-3.1";
      commit = "ae6ed05c623804560afd1cf3d80d13b6170d5c24";
      overrides = {
        displayVersion = "3.1";
      };
    }
  ];

  moduleFromHistory =
    { moduleId
    , commit
    , deployment ? false
    , overrides
    ,
    }:
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
        ${pkgs.jq}/bin/jq --argjson overrides '${builtins.toJSON (overrides)}' '. * $overrides' < ${module} > $out
      '';
    };

  modules = foldl'
    (
      acc: module:
        acc
        // ({
          ${module.moduleId} = moduleFromHistory module;
        })
    )
    { }
    historicalModulesList;

  deploymentModules = foldl'
    (
      acc: module:
        acc
        // ({
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
