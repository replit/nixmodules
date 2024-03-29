{ pkgs, lib, ... }:

let
  bun = pkgs.callPackage ../../bun { };
  bun-wrapped = pkgs.lib.mkWrapper-replit_ld_library_path bun;

  extensions = [ ".js" ".jsx" ".cjs" ".mjs" ".ts" ".tsx" ".mts" ];

  community-version = lib.versions.majorMinor bun.version;
in

{
  id = "bun-${community-version}";
  name = "Bun Tools";
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

  replit.dev.languageServers.typescript-language-server.extensions = extensions ++ [ ".json" ];

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
