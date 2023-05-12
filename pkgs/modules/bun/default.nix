{ pkgs, lib, ... }:

let
  bun = pkgs.callPackage ../../bun { };

  extensions = [ ".js" ".ts" ];

  community-version = lib.versions.majorMinor bun.version;
in

{
  id = "bun-${community-version}";
  name = "Bun Tools";
  version = "1.0";

  imports = [
    (import ../typescript-language-server {
      nodepkgs = pkgs.nodePackages;
    })
  ];

  packages = [
    bun
  ];

  replit.languageServers.typescript-language-server.extensions = extensions;

  replit.runners.bun = {
    name = "bun";
    language = "javascript";
    inherit extensions;

    start = "${bun}/bin/bun run $file";
    fileParam = true;
  };

  replit.packagers.bun = {
    name = "bun";
    language = "bun";
    features = {
      packageSearch = true;
      guessImports = true;
      enabledForHosting = false;
    };
  };
}
