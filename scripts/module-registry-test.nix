let
  apply = import ../pkgs/upgrade-map/apply.nix;
  moduleSet = import ../pkgs/modules/module-set.nix;
  fails = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
  modules = { current = "implementation"; other = "other implementation"; };
  aliases = apply { old = "older"; older = "current"; } modules;
in
assert aliases.old == modules.current;
assert aliases.older == modules.current;
assert aliases.current == modules.current;
assert aliases.other == modules.other;
assert fails (apply { old = "missing"; } modules);
assert fails (apply { old = "old"; } modules);
assert fails (apply { old = "older"; older = "old"; } modules);
assert fails (apply { current = "other"; } modules);
assert fails
  (moduleSet [
    { name = "duplicate"; value = "first"; }
    { name = "duplicate"; value = "second"; }
  ]);
assert moduleSet [
  { name = "current"; value = "implementation"; }
  { name = "other"; value = "other implementation"; }
] == modules;
true
