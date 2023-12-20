# TODO: upstream this file into nixpkgs
{ buildNpmPackage
, fetchurl
}:

buildNpmPackage rec {
  name = "@vue/language-server";
  version = "1.8.25";

  src = fetchurl {
    url = "https://registry.npmjs.org/@vue/language-server/-/language-server-${version}.tgz";
    hash = "sha256-dwciS5zJ1S8q3jqoJ6gzLn5UHpQuTqVNX3BFS5L2B5g=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-vsZqtue2FjMrcKNznD/jhoMXoP96bFzj9E+rTg2SJe8=";
  dontNpmBuild = true;

  meta = {
    mainProgram = "vue-language-server";
  };
}

