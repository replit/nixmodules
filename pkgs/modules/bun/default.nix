# NOTE: Unlike Node.js, nixpkgs doesn't provide versioned bun attributes (e.g., bun_1_3).
# This module uses pkgs.bun which tracks the latest version.
#
# When nixpkgs updates bun to a new major.minor version:
# 1. Add the previous version to pkgs/historical-modules/default.nix, pinned to the
#    commit before the nixpkgs update
# 2. Update pkgs/upgrade-map/default.nix to chain the old version to the new one
{ bun }:
{ pkgs, lib, ... }:

let
  bun-wrapped = pkgs.lib.mkWrapper-replit_ld_library_path bun;

  extensions = [ ".js" ".jsx" ".cjs" ".mjs" ".ts" ".tsx" ".mts" ];

  community-version = lib.versions.majorMinor bun.version;
in

{
  id = "bun-${community-version}";
  name = "Bun Tools";
  description = ''
    Development tools for the Bun JavaScript runtime. Includes Bun runtime, Bun packager and TypeScript language server.
  '';
  displayVersion = bun.version;

  imports = [
    (import ../run-package-json {
      runPackageJsonScript = "${bun-wrapped}/bin/bun run";
      runFileScript = "${bun-wrapped}/bin/bun";
    })
    (import ../typescript-language-server {
      nodepkgs = pkgs.nodePackages;
    })
  ];

  replit.packages = [
    bun-wrapped
  ];

  replit.runners."package.json" = {
    language = "javascript";
    inherit extensions;
  };

  replit.dev.packagers.bun = {
    name = "Bun packager";
    language = "bun";
    features = {
      packageSearch = true;
      guessImports = true;
      enabledForHosting = false;
    };
  };
}
