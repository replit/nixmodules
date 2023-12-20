# TODO: upstream this file into nixpkgs
{ buildNpmPackage
, fetchurl
}:

buildNpmPackage rec {
  name = "@angular/language-server";
  version = "17.0.3";

  src = fetchurl {
    url = "https://registry.npmjs.org/@angular/language-server/-/language-server-${version}.tgz";
    hash = "sha256-Sf5IqJR6Xwa4/LfMMwC8ArxyqcR21xT1f04lYPIpqi0=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-C+3Q48lvJs/YwZSnlKsIREKVTaam9F47t2Kq+JcZJ0w=";
  dontNpmBuild = true;

  meta = {
    mainProgram = "ngserver";
  };
}

