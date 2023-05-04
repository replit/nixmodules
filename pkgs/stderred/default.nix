{ rustPlatform, stderred, makeWrapper }:

rustPlatform.buildRustPackage {
  pname = "stderred";
  version = "0.1.0";

  src = builtins.path { path = ./.; name = "stderred"; };

  cargoSha256 = "sha256-ixJY/O6pE1YJ08GJY4kZ4RaDf+1s17satbOhyBEjyuQ=";

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram "$out/bin/stderred" \
      --set STDERRED_PATH ${stderred}/lib/libstderred.so
  '';
}
