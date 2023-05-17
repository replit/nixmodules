{ pkgs }:
let
mapping = {
  # Examples:
  # "nodejs-18-v1.1" = { to = "nodejs-18-v1.2"; auto = true; };
  # "nodejs-18-v1.2" = { to = "bun-0.5-v1.1"; };
};
in with pkgs.lib.attrsets; {
  auto = mapAttrs (mod: entry: entry.to) (filterAttrs (mod: entry: entry.auto or false) mapping);
  recommend = mapAttrs (mod: entry: entry.to) (filterAttrs (mod: entry: !(entry.auto or false)) mapping);
}