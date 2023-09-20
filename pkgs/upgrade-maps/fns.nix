{ pkgs }: with pkgs.lib;
let
  getShortModuleId = moduleId:
    let parts = strings.splitString ":" moduleId;
    in elemAt parts 0;

  allModules = builtins.fromJSON (builtins.readFile ../../modules.json);

  numericVersion = (moduleId:
    let
      tag = builtins.elemAt (splitString ":" moduleId) 1;
      vNumber = elemAt (splitString "-" tag) 0;
    in
    toInt (substring 1 (-1) vNumber)
  );

  sortByNumericVersion = (moduleIds: sort
    (a: b:
      (numericVersion a) < (numericVersion b)
    )
    moduleIds);

  /*
    stepUpgrade: takes a list of module IDs, and generates
    an upgrade map that step-wise upgrades them:
    stepUpgrade ["A" "B" "C"]
      ->  { "A" = { "to" = "B", auto = true; };
            "B" = { "to" = "C", auto = true; };
          }
  */
  stepUpgrade = ids:
    let
      finalState = foldr
        (id: state:
          if state.prev == null then
            ({ prev = id; upgradeMap = state.upgradeMap; })
          else
            ({
              prev = id;
              upgradeMap = state.upgradeMap // {
                ${id} = { to = state.prev; auto = true; };
              };
            })
        )
        { prev = null; upgradeMap = { }; }
        ids;
    in
    finalState.upgradeMap;

  /*
    linearUpgrade: takes a short module ID, ex "python-3.10",
    takes all of its matching module IDs in modules.json and
    generates upgrade entries for them from the first version to the last
    based on the numeric version.
  */
  linearUpgrade = shortModuleId:
    let
      moduleIds = filter (moduleId: shortModuleId == getShortModuleId moduleId)
        (attrsets.mapAttrsToList (name: value: name) allModules);
    in
    stepUpgrade (sortByNumericVersion moduleIds);

in
{
  inherit stepUpgrade linearUpgrade;
}
