/*
  This implements auto-upgrading from one module ID to another at build time, based on the
  mapping below. This is here for historical purposes, and we don't expect to use it much, although
  there are valid use cases.
*/
with builtins;
let
  upgrade-map = {
    "bun" = "bun-0.5";
    "bun-0.5" = "bun-0.6";
    "bun-0.6" = "bun-0.7";
    "bun-0.7" = "bun-1.0";
    "dart-3.0" = "dart-3.1";
    "dart-3.1" = "dart-3.2";
    "go" = "go-1.19";
    "rust" = "rust-1.69";
    "rust-1.69" = "rust-1.70";
    "rust-1.70" = "rust-1.72";
    "rust-1.72" = "rust-stable";
    "swift" = "swift-5.6";
  };

  upgrade-module = moduleId:
    if hasAttr moduleId upgrade-map then
      upgrade-module upgrade-map.${moduleId}
    else
      moduleId;

  apply-upgrade-map = modules:
    foldl'
      (acc: moduleId:
        let upgraded = upgrade-module moduleId;
        in acc // {
          ${moduleId} = modules.${upgraded};
        }
      )
      modules
      (attrNames upgrade-map);
in
apply-upgrade-map
