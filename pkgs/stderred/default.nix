{ rustPlatform, stderred, makeWrapper }:

rustPlatform.buildRustPackage {
  pname = "stderred";
  version = "0.1.0";

  src = builtins.path { path = ./.; name = "stderred"; };

  cargoSha256 = "sha256-21RJeoGIS+fj/q7rgy80cz50TnEs9WGb+lLGnHTVG2A=";

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram "$out/bin/stderred" \
      --set STDERRED_PATH ${stderred}/lib/libstderred.so
  '';
}
