{ pkgs
, modulesLocks
, self
, upgrade-maps
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
        module-id = elemAt (strings.splitString ":" name) 0;
        m = (flakes.${module.commit}).modules.${module-id};
      in
      # verify the outpath matches what the lockfile expects
      assert m.outPath == module.path;
      m)
    modulesLocks;

  active-modules = import ../active-modules {
    inherit pkgs self modulesLocks;
  };

in

(pkgs.linkFarm "nixmodules-bundle" ([
  {
    name = "etc/nixmodules/modules.json";
    path = builtins.toFile "modules.json" (builtins.toJSON modulesLocks);
  }
  {
    name = "etc/nixmodules/active-modules.json";
    path = active-modules;
  }
  {
    name = "etc/nixmodules/auto-upgrade.json";
    path = "${upgrade-maps}/auto-upgrade.json";
  }
  {
    name = "etc/nixmodules/recommend-upgrade.json";
    path = "${upgrade-maps}/recommend-upgrade.json";
  }
] ++ (
  mapAttrsToList (name: value: { inherit name; path = value; }) modules
))).overrideAttrs (finalAttrs: previousAttrs: {
  passthru = {
    inherit active-modules;
  };
})
