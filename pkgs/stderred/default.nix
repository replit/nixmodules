{ rustPlatform, stderred, makeWrapper }:

rustPlatform.buildRustPackage {
  pname = "stderred";
  version = "0.1.0";

  src = builtins.path { path = ./.; name = "stderred"; };

  cargoSha256 = "sha256-1L/5mEjSN3zTCYHFWRBW6ODqMLQ2yyvfzUZY0o3aanE=";

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram "$out/bin/stderred" \
      --set STDERRED_PATH ${stderred}/lib/libstderred.so
  '';
}
