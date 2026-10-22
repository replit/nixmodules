# NOTE: Unlike Node.js, nixpkgs doesn't provide versioned bun attributes (e.g., bun_1_3).
# This module uses pkgs.bun which tracks the latest version.
#
# When nixpkgs updates bun to a new major.minor version, either retain the old
# package pin and register both versions, or retire the old implementation and
# map its ID to the new version in pkgs/upgrade-map/default.nix. Do not do both.
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
