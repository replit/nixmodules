{ pkgs, pkgs-unstable, lib, ... }:

let
  bun = pkgs-unstable.callPackage ../../bun { };

  extensions = [ ".json" ".js" ".jsx" ".ts" ".tsx" ];

  community-version = lib.versions.majorMinor bun.version;

  package-json-runner = pkgs.writeScript "bun-runner" ''
    #!${pkgs.bash}/bin/bash
    if start=$(${pkgs.jq}/bin/jq -r '.scripts.start? // empty' package.json 2>/dev/null); [[ -n $start ]]; then
      echo "+ bun run start";
      ${bun}/bin/bun run start;
    elif module=$(${pkgs.jq}/bin/jq -r 'if .type == "module" then .module // empty else empty end' package.json 2>/dev/null); [[ -n $module ]]; then
      echo "+ bun $module";
      ${bun}/bin/bun $module;
    elif main=$(${pkgs.jq}/bin/jq -r '.main // empty' package.json 2>/dev/null); [[ -n $main ]]; then
      echo "+ bun $main";
      ${bun}/bin/bun $main;
    elif [[ -n $file ]]; then
      echo "+ bun $file";
      ${bun}/bin/bun $file;
    fi
  '';
in

{
  id = "bun-${community-version}";
  name = "Bun Tools";

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

    start = "${package-json-runner}";
    optionalFileParam = true;
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
