entries:
let
  modules = builtins.listToAttrs entries;
in
if builtins.length entries != builtins.length (builtins.attrNames modules) then
  throw "Duplicate module implementation ID"
else
  modules
