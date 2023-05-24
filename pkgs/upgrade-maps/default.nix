{ pkgs }:
with pkgs.lib.attrsets;
let
mapping = {
  # Examples:
  #"bun-0.5:v1-20230522-49470df" = { to = "bun-0.5:v2-20230522-0f45db1"; auto = true; changelog = "A better lsp!"; };
  #"bun-0.5:v2-20230522-0f45db1" = { to = "bun-0.5:v3-20230522-9e0a3f9"; auto = true; changelog = "bug fix"; };
  #"nodejs-16:v1-20230522-49470df" = { to = "nodejs-16:v2-20230522-4c01fa0"; auto = true; changelog = "improved your experience"; };
  #"nodejs-14:v3-20230522-36692ed" = { to = "nodejs-18:v3-20230522-36692ed"; changelog = "Node.js 14 is deprecated. Upgrade to 18!"; };
  #"nodejs-16:v3-20230522-36692ed" = { to = "nodejs-18:v3-20230522-36692ed"; changelog = "Node.js 16 is deprecated. Upgrade to 18!"; };
  "go" = { to = "go-1.19:v2-20230523-b8111f7"; };
  "rust" = { to = "rust-1.69:v1-20230523-b8111f7"; };
  "swift" = { to = "swift-5.6:v2-20230523-b8111f7"; };
};

present-entries = entries: mapAttrs (mod: entry: 
(if builtins.hasAttr "changelog" entry then {
  inherit (entry) to changelog;
} else {
  inherit (entry) to;
})) entries;
filter-auto = filterAttrs (mod: entry: entry.auto or false);
filter-recommend = filterAttrs (mod: entry: !(entry.auto or false));
auto = present-entries (filter-auto mapping);
recommend = present-entries (filter-recommend mapping);
in
pkgs.stdenv.mkDerivation {
  pname = "upgrade-maps";
  version = "1.0.0";
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
  mkdir $out
  echo '${builtins.toJSON auto}' > $out/auto-upgrade.json
  echo '${builtins.toJSON recommend}' > $out/recommend-upgrade.json
  '';
  passthru = {
    # this allows you to query for this info wo building it:
    # nix eval .#upgrade-maps.meta.auto --json
    # nix eval .#upgrade-maps.meta.recommend --json
    inherit auto;
    inherit recommend;
  };
}
