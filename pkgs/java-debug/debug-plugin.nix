{ stdenv
, maven
, fetchFromGitHub
, jdk
, callPackage
}:
let
  version = "0.37.0";

  src = fetchFromGitHub {
    owner = "replit";
    repo = "java-debug";
    rev = "main";
    sha256 = "RR3Atw2B5ttT+K10wGD+OsDOeMlcNVEqA/7ZTixCXCQ=";
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
