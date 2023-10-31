{ pkgs }:
with pkgs.lib.attrsets;
let
  fns = import ./fns.nix { inherit pkgs; };

  mapping = import ./mapping.nix pkgs;

  present-entries = entries: mapAttrs
    (mod: entry:
      (
        if builtins.hasAttr "changelog" entry
        then { inherit (entry) to changelog; }
        else { inherit (entry) to; }
      ))
    entries;
  filter-auto = filterAttrs (mod: entry: entry.auto or false);
  filter-recommend = filterAttrs (mod: entry: !(entry.auto or false));
  auto = present-entries (filter-auto mapping);
  recommend = present-entries (filter-recommend mapping);

  auto-upgrades-file = pkgs.writeTextFile {
    name = "auto-upgrades";
    text = builtins.toJSON auto;
    destination = "/auto-upgrade.json";
  };
  recommended-upgrades-file = pkgs.writeTextFile {
    name = "recommend-upgrades";
    text = builtins.toJSON recommend;
    destination = "/recommend-upgrade.json";
  };

  modules = builtins.fromJSON (builtins.readFile ../../modules.json);

  # A module is terminal if it doesn't have an upgrade mapping, or the
  # upgrade mapping doesn't have auto = true.
  isTerminal = mod: !((mapping.${mod} or false).auto or false);

  moduleToTerminal =
    mapAttrs
    (mod: _: isTerminal mod)
    modules;

  terminalAndPreviousModuleLocks =
    filterAttrs
    # either the module is terminal, or it maps directly to a terminal module
    (mod: _: moduleToTerminal.${mod} || (moduleToTerminal.${mapping.${mod}.to} or false))
    modules;

in
pkgs.symlinkJoin {
  name = "upgrade-maps";

  paths = [
    auto-upgrades-file
    recommended-upgrades-file
  ];

  passthru = {
    # this allows you to query for this info wo building it:
    # nix eval .#upgrade-maps.meta.auto --json
    # nix eval .#upgrade-maps.meta.recommend --json
    inherit auto;
    inherit recommend;
    inherit terminalAndPreviousModuleLocks;
  };
}
