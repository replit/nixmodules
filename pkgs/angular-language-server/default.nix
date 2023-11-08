{
  # buildBazelPackage,
  buildNpmPackage,
  fetchFromGitHub,
  fetchurl,
  lib,
  stdenvNoCC,
  symlinkJoin,
  typescript,
  xorg
}:

let
  pname = "@angular/language-server";
  version = "17.0.0";

  npmSrc = fetchurl {
    url = "https://registry.npmjs.org/@angular/language-server/-/language-server-${version}.tgz";
    hash = "sha256-BTKQjD4UkAl0mKkpjLJpdYZ9/XzfLsdXU5xDcKW9UQ8=";
  };

  repoSrc = fetchFromGitHub {
    owner = "angular";
    repo = "vscode-ng-language-service";
    rev = "v17.0.0";
    hash = "sha256-NiPttPH+A5Jvh4b4ynMqgTWuf47Uh9Fnkd+kv24w+kA=";
  };

  # builtRepoSrc = buildBazelPackage {
  #   inherit pname version;

  #   src = repoSrc;
  # };
# in

# stdenvNoCC.mkDerivation {
#   name = "foo";
#   src = npmSrc;

#   installPhase = ''
#     mkdir -p $out
#     cp -r ./* $out
#   '';

#   postPatch = ''
#     cp ${./package-lock.json} ./package-lock.json
#     echo === LS ===
#     ls -al
#   '';
# }

# buildBazelPackage {
#   inherit pname version;

#   src =

#   bazelTargets = [
#     "//server/npm_files"
#   ];
# }
in

buildNpmPackage {
  inherit pname version;

  src = npmSrc;
  # sourceRoot = "source/server";

  npmDepsHash = "sha256-CPGFIOQbGKsYgq9aLS1Nt9AE3vh8HWk5CYHmjZVqBNs=";

  npmPackFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;
  postPatch = ''
    cp ${./package-lock.json} ./package-lock.json
    # ls -al
  '';

  postInstall = ''
    echo === LS ===
    ls -al $out/lib/node_modules/@angular/language-server
    cp -r ${typescript}/lib/node_modules/typescript $out/lib/node_modules/@angular/language-server/node_modules
  '';

  meta = {
    mainProgram = "ngserver";
  };
}