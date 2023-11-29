{ pkgs, pkgs-unstable, lib, ... }:

let
  bun = pkgs-unstable.callPackage ../../bun { };

  extensions = [ ".json" ".js" ".jsx" ".ts" ".tsx" ];

  community-version = lib.versions.majorMinor bun.version;
in

{
  id = "bun-${community-version}";
  name = "Bun Tools";

  imports = [
    (import ../run-package-json {
      runPackageJsonScript = "${bun}/bin/bun run";
      runFileScript = "${bun}/bin/bun";
    })
    (import ../typescript-language-server {
      nodepkgs = pkgs.nodePackages;
    })
  ];

  replit.packages = [
    bun
  ];

  replit.dev.languageServers.typescript-language-server.extensions = extensions;

  replit.runners."package.json" = {
    language = "javascript";
    inherit extensions;
  };

  replit.dev.packagers.bun = {
    name = "bun";
    language = "bun";
    features = {
      packageSearch = true;
      guessImports = true;
      enabledForHosting = false;
    };
  };
}
