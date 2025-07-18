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

  cargoHash = "sha256-n6rGDpkkPwBB6BV97DXrL3NZnCa71YgAGXEI5bymbLw=";

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram "$out/bin/stderred" \
      --set STDERRED_PATH ${stderred}/lib/libstderred.so
  '';
}
