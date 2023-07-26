{ pkgs
, revstring
, modulesLocks
}:

with pkgs.lib;

let
  commits = unique (catAttrs "commit" (builtins.attrValues modulesLocks));

  flakes = builtins.listToAttrs (
    map
      (commit: {
        name = commit;
        value = builtins.getFlake "github:replit/nixmodules/${commit}";
      })
      commits);

  modules = builtins.mapAttrs
    (name: module:
      let
        moduleId = elemAt (strings.splitString ":" name) 0;
        m = (flakes.${module.commit}).modules.${moduleId};
      in
      # verify the outpath matches what the lockfile expects
      assert m.outPath == module.path;
      m)
    modulesLocks;

in

pkgs.linkFarm "nixmodules-bundle-${revstring}" (
  mapAttrsToList (name: value: { inherit name; path = value; }) modules
)
