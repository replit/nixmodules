{ pkgs, revstring,
  moduleIds ? null # null means include all module IDs
}:

with pkgs.lib;

let
  modulesLocks = (builtins.fromJSON (builtins.readFile ../../modules.json));

  locksModuleIds = mapAttrsToList (mid: _: mid) modulesLocks;

  numericVersion = (moduleId:
    let tag = builtins.elemAt (splitString ":" moduleId) 1;
    vNumber = elemAt (splitString "-" tag) 0;
    in
      toInt (substring 1 (-1) vNumber)
  );

  allVersionsForModule = (moduleId:
    filter (mid: strings.hasPrefix moduleId mid) locksModuleIds
  );

  sortByNumericVersion = (moduleIds: sort (a: b:
    (numericVersion a) > (numericVersion b)
  ) moduleIds);

  filteredModulesLocks =
    if moduleIds == null
    then modulesLocks
    else
      foldr (
        moduleId: locks:
        if strings.hasInfix ":" moduleId then
          (locks // {
            ${moduleId} = modulesLocks.${moduleId};
          })
        else
          # for convinience of A/B testing against last version,
          # grab the latest 2 versions of specified module
          let
            myModuleIds = allVersionsForModule moduleId;
            mySortedModuleIds = sortByNumericVersion myModuleIds;
            top2 = take 2 mySortedModuleIds;
            in
              (locks // foldr (mid: locks:
                locks // {
                  ${mid} = modulesLocks.${mid};
                }
              ) { } top2)
      )
      { }
      moduleIds;

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
    filteredModulesLocks;

in

pkgs.linkFarm "nixmodules-bundle-${revstring}" (
  mapAttrsToList (name: value: { inherit name; path = value; }) modules
)
