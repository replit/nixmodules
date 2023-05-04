{ stdenv
, maven
, fetchFromGitHub
, jdk
, callPackage
}:
let
  version = "0.32.0";

  src = fetchFromGitHub {
    owner = "replit";
    repo = "java-debug";
    rev = "debug-interface";
    sha256 = "14ada9chynzycnfqc4w9c1w24gyx37by81fyb9y42izdrn46dj2z";
  };
  repository = callPackage ./repo.nix {
    inherit src jdk patches;
  };

  patches = [
    ./patches/repo.diff
  ];

in
stdenv.mkDerivation {
  inherit version src patches;
  name = "java-debug-plugin";

  buildInputs = [ maven jdk ];
  buildPhase = ''
    # Maven tries to grab lockfiles in the repository, so it has to be writeable
    cp -a ${repository} ./repository
    chmod u+w -R ./repository
    ${maven}/bin/mvn --offline -Dmaven.repo.local=./repository package
  '';

  installPhase = ''
    mkdir -p $out/lib
    cp com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-${version}.jar $out/lib/java-debug.jar
  '';
}
