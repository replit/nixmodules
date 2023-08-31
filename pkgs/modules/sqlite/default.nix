{ pkgs, lib, replit-prompt, ... }:

let
  inherit (pkgs) sqlite;
  version = lib.versions.majorMinor sqlite.version;

  run-smallbar-name = "smallbar-sqlite";
  run-smallbar = pkgs.writeScriptBin run-smallbar-name ''
    smallbar \
      -detect-ps1 "sqlite>" \
      -replace-ps1 "${replit-prompt}" \
      -skip-interp \
      -replace-run \
      -t sqlite3 \
      -r "${sqlite}/bin/sqlite3 init" \
      $@
  '';
in

{
  id = "sqlite-${version}";
  name = "SQLite ${version} Tools";

  packages = [
    sqlite
  ];

  replit.runners.sqlite-smallbar = {
    name = "SQLite in smallbar";
    language = "sqlite";
    optionalFileParam = true;
    interpreter = true;
    start = "${run-smallbar}/bin/${run-smallbar-name} $file";
  };
}
