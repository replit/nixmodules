{ pkgs }:
with pkgs.lib.attrsets;
let
  fns = import ./fns.nix { inherit pkgs; };
  mapping = {
    # Examples:
    #"bun-0.5:v1-20230522-49470df" = { to = "bun-0.5:v2-20230522-0f45db1"; auto = true; changelog = "A better lsp!"; };
    #"bun-0.5:v2-20230522-0f45db1" = { to = "bun-0.5:v3-20230522-9e0a3f9"; auto = true; changelog = "bug fix"; };
    #"nodejs-16:v1-20230522-49470df" = { to = "nodejs-16:v2-20230522-4c01fa0"; auto = true; changelog = "improved your experience"; };
    #"nodejs-14:v3-20230522-36692ed" = { to = "nodejs-18:v3-20230522-36692ed"; changelog = "Node.js 14 is deprecated. Upgrade to 18!"; };
    #"nodejs-16:v3-20230522-36692ed" = { to = "nodejs-18:v3-20230522-36692ed"; changelog = "Node.js 16 is deprecated. Upgrade to 18!"; };
    # // (fns.linearUpgrade "python-3.10")
    # // (fns.stepUpgrade [
    #       "bun-0.5:v1-20230525-c48c43c"
    #       "bun-0.6:v1-20230607-15011da"
    #       "bun-0.7:v1-20230724-4274858"
    #     ])

    "bun" = { to = "bun-0.5:v1-20230525-c48c43c"; auto = true; };
    "bun-0.5:v1-20230525-c48c43c" = { to = "bun-0.6:v1-20230607-15011da"; auto = true; };
    "bun-0.6:v1-20230607-15011da" = { to = "bun-0.6:v2-20230608-10cb54c"; auto = true; };
    "bun-0.6:v2-20230608-10cb54c" = { to = "bun-0.6:v3-20230623-0b7a606"; auto = true; };
    "bun-0.6:v3-20230623-0b7a606" = { to = "bun-0.6:v4-20230721-719ce58"; auto = true; };
    "bun-0.6:v4-20230721-719ce58" = { to = "bun-0.7:v1-20230724-4274858"; auto = true; };
    "bun-0.7:v1-20230724-4274858" = { to = "bun-1.0:v1-20230911-f253fb1"; auto = true; changelog = "bun 1.0.0 release"; };
    "bun-1.0:v1-20230911-f253fb1" = { to = "bun-1.0:v2-20230913-4d3c541"; auto = true; changelog = "bun 1.0.1 release"; };
    "bun-1.0:v2-20230913-4d3c541" = { to = "bun-1.0:v3-20230915-80b0f23"; auto = true; changelog = "bun 1.0.2 release"; };
    "bun-1.0:v4-20230915-82a14e9" = {
      to = "bun-1.0:v3-20230915-80b0f23";
      auto = true;
      changelog = ''**REVERTED.** The script tries to open `/nix/store`, which, being ~18tb, takes
      a *long* time to complete. As such, the new `package.json` runner script shouldn't be used.

      # `package.json` runner
        The runner for bun module has changed for increased flexibility and conformance to standards.

        The new precedence is:
        - the `replit-dev` script defined in `package.json`
        - the `dev` script defined in `package.json`
        - the `main` file defined in `package.json`
        - the `entrypoint` defined in `.replit`
      '';
    };
    "bun-1.0:v5-20230921-cc7a2dd" = { to = "bun-1.0:v3-20230915-80b0f23"; auto = true; };
    "bun-1.0:v3-20230915-80b0f23" = { to = "bun-1.0:v6-20231002-0b7fed5"; auto = true; };
    "bun-1.0:v6-20231002-0b7fed5" = { to = "bun-1.0:v7-20231013-71b6704"; auto = true; changelog = "bun 1.0.6 release"; };
    "bun-1.0:v7-20231013-71b6704" = {
      to = "bun-1.0:v8-20231013-f38c84f";
      auto = true;
      changelog = ''# `package.json` runner
        The runner for bun module has changed for increased flexibility and conformance to standards.

        The new precedence is:
        - the `replit-dev` script defined in `package.json`
        - the `dev` script defined in `package.json`
        - the `entrypoint` defined in `.replit`
        - the `main` file defined in `package.json`
      '';
    };
    "bun-1.0:v8-20231013-f38c84f" = { to = "bun-1.0:v9-20231024-b3ba53c"; auto = true; };

    "go" = { to = "go-1.19:v1-20230525-c48c43c"; auto = true; };

    "rust" = { to = "rust-1.69:v1-20230525-c48c43c"; auto = true; };
    "rust-1.69:v1-20230525-c48c43c" = { to = "rust-1.69:v2-20230623-0b7a606"; auto = true; };
    "rust-1.69:v2-20230623-0b7a606" = { to = "rust-1.70:v1-20230724-17660e5"; auto = true; };
    "rust-1.70:v1-20230724-17660e5" = { to = "rust-1.72:v1-20230911-f253fb1"; auto = true; };
    "rust-1.72:v1-20230911-f253fb1" = { to = "rust-stable:v1-20231012-19c270f"; auto = true; };

    "swift" = { to = "swift-5.6:v1-20230525-c48c43c"; auto = true; };
  }
  // (fns.linearUpgrade "c-clang14")
  // (fns.linearUpgrade "clojure-1.11")
  // (fns.linearUpgrade "cpp-clang14")
  // (fns.linearUpgrade "docker")
  // (fns.linearUpgrade "dotnet-7.0")
  // (fns.linearUpgrade "go-1.20")
  // (fns.linearUpgrade "haskell-ghc9.2")
  // (fns.linearUpgrade "java-graalvm22.3")
  // (fns.linearUpgrade "lua-5.2")
  // (fns.linearUpgrade "nodejs-14")
  // (fns.linearUpgrade "nodejs-16")
  // (fns.linearUpgrade "nodejs-18")
  // (fns.linearUpgrade "nodejs-19")
  // (fns.linearUpgrade "nodejs-20")
  // (fns.linearUpgrade "nodejs-with-prybar-18")
  // (fns.linearUpgrade "php-8.1")
  // (fns.linearUpgrade "pyright-extended")
  // (fns.linearUpgrade "python-3.10")
  // (fns.linearUpgrade "python-3.11")
  // (fns.linearUpgrade "python-3.8")
  // (fns.linearUpgrade "python-with-prybar-3.10")
  // (fns.linearUpgrade "qbasic")
  // (fns.linearUpgrade "r-4.2")
  // (fns.linearUpgrade "ruby-3.1")
  // (fns.linearUpgrade "svelte-kit-node-20")
  // (fns.linearUpgrade "swift-5.8")
  // (fns.linearUpgrade "web")
  ;

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
  };
}
