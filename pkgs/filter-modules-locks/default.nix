{ pkgs,
  moduleIds ? null
  # moduleIds is a list of fully or partially resolved module IDs, 
  #   or null which means include all module IDs.
  # fully resolved module ID ex: ["php-8.1:v1-20230525-c48c43c" "python-3.10:v10-20230711-6807d41"]
  # partially resolved module ID ex: ["python-3.10" "nodejs-18"]
  #   - when a partially resolved ID is used, the latest 2 versions of that module will be built
}:
with builtins; with pkgs.lib;
let
  modulesLocks = (builtins.fromJSON (builtins.readFile ../../modules.json));

  locksModuleIds = mapAttrsToList (mid: _: mid) modulesLocks;

  numericVersion = (moduleId:
    let
      tag = builtins.elemAt (splitString ":" moduleId) 1;
      vNumber = elemAt (splitString "-" tag) 0;
    in
    toInt (substring 1 (-1) vNumber)
  );

  allVersionsForModule = (moduleId:
    filter (mid: strings.hasPrefix moduleId mid) locksModuleIds
  );

  sortByNumericVersion = (moduleIds: sort
    (a: b:
      (numericVersion a) > (numericVersion b)
    )
    moduleIds);

  filteredModulesLocks =
    if moduleIds == null
    then modulesLocks
    else
      foldr
        (
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
              (locks // foldr
                (mid: locks:
                  locks // {
                    ${mid} = modulesLocks.${mid};
                  }
                )
                { }
                top2)
        )
        { }
        moduleIds;
  in filteredModulesLocks