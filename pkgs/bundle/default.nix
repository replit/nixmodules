/*

  Returns a function taking:
* a list of module IDs to filter by
  Returns a derivation that builds a directory containing:
* /etc/nixmodules/modules.json
* a symlink per module ID passed in, resolving to a JSON file containing
   the toolchain supplied by that module

*/
{ pkgs, lib, self, ... }:
with builtins;
with pkgs.lib;
{ moduleIds ? null }:
let
  modules = self.modules;
  filteredModules =
    if moduleIds == null
    then modules else
      filterAttrs (moduleId: _: elem moduleId moduleIds) modules;
  modulesMap = mapAttrs
    (name: drv: {
      path = drv.outPath;
    })
    filteredModules;
in
pkgs.linkFarm "nixmodules-bundle" ([
  {
    name = "etc/nixmodules/modules.json";
    path = pkgs.writeTextFile {
      name = "modules.json";
      text = builtins.toJSON modulesMap;
    };
  }
] ++ (mapAttrsToList (name: value: { inherit name; path = value; }) filteredModules))
