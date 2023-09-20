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

    "bun" = { to = "bun-0.5:v1-20230525-c48c43c"; auto = true; };
    "bun-0.5:v1-20230525-c48c43c" = { to = "bun-0.6:v1-20230607-15011da"; auto = true; };
    "bun-0.6:v1-20230607-15011da" = { to = "bun-0.6:v2-20230608-10cb54c"; auto = true; };
    "bun-0.6:v2-20230608-10cb54c" = { to = "bun-0.6:v3-20230623-0b7a606"; auto = true; };
    "bun-0.6:v3-20230623-0b7a606" = { to = "bun-0.6:v4-20230721-719ce58"; auto = true; };
    "bun-0.6:v4-20230721-719ce58" = { to = "bun-0.7:v1-20230724-4274858"; auto = true; };
    "bun-0.7:v1-20230724-4274858" = { to = "bun-1.0:v1-20230911-f253fb1"; auto = true; changelog = "bun 1.0.0 release"; };
    "bun-1.0:v1-20230911-f253fb1" = { to = "bun-1.0:v2-20230913-4d3c541"; auto = true; changelog = "bun 1.0.1 release"; };
    "bun-1.0:v2-20230913-4d3c541" = { to = "bun-1.0:v3-20230915-80b0f23"; auto = true; changelog = "bun 1.0.2 release"; };
    "bun-1.0:v3-20230915-80b0f23" = {
      to = "bun-1.0:v4-20230915-82a14e9";
      auto = true;
      changelog = ''# `package.json` runner
        The runner for bun module has changed for increased flexibility and conformance to standards.

        The new precedence is:
        - the `replit-dev` script defined in `package.json`
        - the `dev` script defined in `package.json`
        - the `main` file defined in `package.json`
        - the `entrypoint` defined in `.replit`
      '';
    };

    "go" = { to = "go-1.19:v1-20230525-c48c43c"; auto = true; };
    "go-1.19:v1-20230525-c48c43c" = { to = "go-1.20:v1-20230623-0b7a606"; auto = true; };
    "go-1.20:v1-20230623-0b7a606" = { to = "go-1.20:v2-20230911-b5aa5df"; auto = true; };

    "java-graalvm22.3:v1-20230525-c48c43c" = { to = "java-graalvm22.3:v2-20230623-0b7a606"; auto = true; };
    "java-graalvm22.3:v2-20230623-0b7a606" = { to = "java-graalvm22.3:v3-20230707-3ef18cf"; auto = true; };
    "java-graalvm22.3:v3-20230707-3ef18cf" = { to = "java-graalvm22.3:v4-20230823-ef0f43c"; auto = true; };

    "nodejs-14:v1-20230525-c48c43c" = { to = "nodejs-14:v2-20230605-9621162"; auto = true; };
    "nodejs-14:v2-20230605-9621162" = { to = "nodejs-18:v2-20230605-9621162"; changelog = "Node.js 14 is deprecated. Upgrade to 18!"; };

    "nodejs-16:v1-20230525-c48c43c" = { to = "nodejs-16:v2-20230605-9621162"; auto = true; };
    "nodejs-16:v2-20230605-9621162" = { to = "nodejs-18:v2-20230605-9621162"; changelog = "Node.js 16 is deprecated. Upgrade to 18!"; };

    "nodejs-18:v1-20230525-c48c43c" = { to = "nodejs-18:v2-20230605-9621162"; auto = true; };
    "nodejs-18:v2-20230605-9621162" = { to = "nodejs-18:v3-20230608-f4cd419"; auto = true; };
    "nodejs-18:v3-20230608-f4cd419" = { to = "nodejs-18:v4-20230623-0b7a606"; auto = true; };
    "nodejs-18:v4-20230623-0b7a606" = { to = "nodejs-18:v5-20230706-ccb32c4"; auto = true; };
    "nodejs-18:v5-20230706-ccb32c4" = { to = "nodejs-18:v6-20230711-6807d41"; auto = true; };
    "nodejs-18:v6-20230711-6807d41" = { to = "nodejs-18:v7-20230905-8d7bacf"; auto = true; };
    "nodejs-18:v7-20230905-8d7bacf" = { to = "nodejs-18:v8-20230907-87be05d"; auto = true; };
    "nodejs-18:v8-20230907-87be05d" = { to = "nodejs-18:v9-20230908-bb1b9fd"; auto = true; };
    "nodejs-18:v9-20230908-bb1b9fd" = { to = "nodejs-18:v10-20230914-1095880"; auto = true; };
    "nodejs-18:v10-20230914-1095880" = { to = "nodejs-18:v11-20230920-bd784b9"; auto = true; };

    "nodejs-19:v1-20230525-c48c43c" = { to = "nodejs-19:v2-20230605-9621162"; auto = true; };

    "nodejs-20:v1-20230623-0b7a606" = { to = "nodejs-20:v2-20230706-ccb32c4"; auto = true; };
    "nodejs-20:v2-20230706-ccb32c4" = { to = "nodejs-20:v3-20230711-6807d41"; auto = true; };
    "nodejs-20:v3-20230711-6807d41" = { to = "nodejs-20:v4-20230905-8d7bacf"; auto = true; };
    "nodejs-20:v4-20230905-8d7bacf" = { to = "nodejs-20:v5-20230907-87be05d"; auto = true; };
    "nodejs-20:v5-20230907-87be05d" = { to = "nodejs-20:v6-20230908-bb1b9fd"; auto = true; };
    "nodejs-20:v6-20230908-bb1b9fd" = { to = "nodejs-20:v7-20230914-1095880"; auto = true; };
    "nodejs-20:v7-20230914-1095880" = { to = "nodejs-20:v8-20230920-bd784b9"; auto = true; };

    "php-8.1:v1-20230525-c48c43c" = { to = "php-8.1:v2-20230623-0b7a606"; auto = true; };

    "python-3.8:v1-20230829-e1c0916" = { to = "python-3.8:v2-20230907-3d66d15"; auto = true; };
    "python-3.8:v2-20230907-3d66d15" = { to = "python-3.8:v3-20230914-1095880"; auto = true; };
    "python-3.8:v3-20230914-1095880" = { to = "python-3.8:v4-20230920-bd784b9"; auto = true; };
    "python-3.8:v4-20230920-bd784b9" = { to = "python-3.8:v5-20230920-d4ad2e4"; auto = true; };

    "python-3.10:v5-20230613-622effa" = { to = "python-3.10:v6-20230614-6eb09f7"; auto = true; };
    "python-3.10:v6-20230614-6eb09f7" = { to = "python-3.10:v7-20230623-0b7a606"; auto = true; };
    "python-3.10:v7-20230623-0b7a606" = { to = "python-3.10:v8-20230629-218abef"; auto = true; };
    "python-3.10:v8-20230629-218abef" = { to = "python-3.10:v9-20230706-ccb32c4"; auto = true; };
    "python-3.10:v9-20230706-ccb32c4" = { to = "python-3.10:v10-20230711-6807d41"; auto = true; };
    "python-3.10:v10-20230711-6807d41" = { to = "python-3.10:v11-20230711-eb29cca"; auto = true; };
    "python-3.10:v11-20230711-eb29cca" = { to = "python-3.10:v12-20230712-7266cd2"; auto = true; };
    "python-3.10:v12-20230712-7266cd2" = { to = "python-3.10:v13-20230712-4ba5dba"; auto = true; };
    "python-3.10:v13-20230712-4ba5dba" = { to = "python-3.10:v14-20230713-b6f899f"; auto = true; };
    "python-3.10:v14-20230713-b6f899f" = { to = "python-3.10:v15-20230717-2dadc92"; auto = true; };
    "python-3.10:v15-20230717-2dadc92" = { to = "python-3.10:v16-20230726-64244b3"; auto = true; };
    "python-3.10:v16-20230726-64244b3" = { to = "python-3.10:v17-20230803-f57c5cc"; auto = true; };
    "python-3.10:v17-20230803-f57c5cc" = { to = "python-3.10:v18-20230807-322e88b"; auto = true; };
    "python-3.10:v18-20230807-322e88b" = { to = "python-3.10:v19-20230816-9932e6a"; auto = true; };
    "python-3.10:v19-20230816-9932e6a" = { to = "python-3.10:v20-20230824-f46249a"; auto = true; };
    "python-3.10:v20-20230824-f46249a" = { to = "python-3.10:v21-20230831-f4ed402"; auto = true; };
    "python-3.10:v21-20230831-f4ed402" = { to = "python-3.10:v22-20230914-1095880"; auto = true; };
    "python-3.10:v22-20230914-1095880" = { to = "python-3.10:v23-20230918-15fb6e7"; auto = true; };
    "python-3.10:v23-20230918-15fb6e7" = { to = "python-3.10:v24-20230920-bd784b9"; auto = true; };
    "python-3.10:v24-20230920-bd784b9" = { to = "python-3.10:v25-20230920-d4ad2e4"; auto = true; };

    "python-3.11:v1-20230828-e4baa21" = { to = "python-3.11:v2-20230831-f4ed402"; auto = true; };
    "python-3.11:v2-20230831-f4ed402" = { to = "python-3.11:v3-20230914-1095880"; auto = true; };
    "python-3.11:v3-20230914-1095880" = { to = "python-3.11:v4-20230918-15fb6e7"; auto = true; };
    "python-3.11:v4-20230918-15fb6e7" = { to = "python-3.11:v5-20230920-bd784b9"; auto = true; };
    "python-3.11:v5-20230920-bd784b9" = { to = "python-3.11:v6-20230920-d4ad2e4"; auto = true; };

    "pyright-extended:v1-20230707-0c33b22" = { to = "pyright-extended:v2-20230711-eb29cca"; auto = true; };
    "pyright-extended:v2-20230711-eb29cca" = { to = "pyright-extended:v3-20230712-4ba5dba"; auto = true; };
    "pyright-extended:v3-20230712-4ba5dba" = { to = "pyright-extended:v4-20230717-2dadc92"; auto = true; };
    "pyright-extended:v4-20230717-2dadc92" = { to = "pyright-extended:v5-20230807-322e88b"; auto = true; };
    "pyright-extended:v5-20230807-322e88b" = { to = "pyright-extended:v6-20230816-9932e6a"; auto = true; };
    "pyright-extended:v6-20230816-9932e6a" = { to = "pyright-extended:v7-20230831-f4ed402"; auto = true; };

    "rust" = { to = "rust-1.69:v1-20230525-c48c43c"; auto = true; };

    "svelte-kit-node-20:v1-20230724-46059dd" = { to = "svelte-kit-node-20:v2-20230728-64881db"; auto = true; };

    "swift" = { to = "swift-5.6:v1-20230525-c48c43c"; auto = true; };
  };

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
