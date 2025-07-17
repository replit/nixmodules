{ rustPlatform
, stderred
, makeWrapper
,
}:

rustPlatform.buildRustPackage {
  pname = "stderred";
  version = "0.1.0";

  src = builtins.path {
    path = ./.;
    name = "stderred";
  };

  cargoHash = "sha256-Fc5ZP/ARqcNdwU5t/xarhsEglbYCNo2XVsJjdHT+/DA=";

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram "$out/bin/stderred" \
      --set STDERRED_PATH ${stderred}/lib/libstderred.so
  '';
}
