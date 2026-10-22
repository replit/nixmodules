aliases: modules:
with builtins;
let
  resolve = seen: id:
    if elem id seen then
      throw "Module alias cycle: ${concatStringsSep " -> " (seen ++ [ id ])}"
    else if hasAttr id aliases then
      resolve (seen ++ [ id ]) aliases.${id}
    else if hasAttr id modules then
      id
    else
      throw "Module alias target has no implementation: ${id}";

  resolved = mapAttrs (id: _: resolve [ ] id) aliases;
  collisions = filter (id: hasAttr id modules) (attrNames aliases);
in
if collisions != [ ] then
  throw "Module aliases shadow implementations: ${concatStringsSep ", " collisions}"
else
  deepSeq resolved (modules // mapAttrs (_: target: modules.${target}) resolved)
