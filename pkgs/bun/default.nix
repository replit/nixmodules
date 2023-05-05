{ lib
, stdenvNoCC
, callPackage
, fetchurl
, autoPatchelfHook
, unzip
, openssl
, writeShellScript
, curl
, jq
, common-updater-scripts
}:

stdenvNoCC.mkDerivation {
  version = "0.5.9";
  pname = "bun";

  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v0.5.9/bun-linux-x64.zip";
    sha256 = "vwxkydYJdnb8MBUAfywpXdaahsuw5IvnXeoUmilzruE=";
  };

  strictDeps = true;
  nativeBuildInputs = [ unzip ] ++ lib.optionals stdenvNoCC.isLinux [ autoPatchelfHook ];
  buildInputs = [ openssl ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm 755 ./bun $out/bin/bun
    runHook postInstall
  '';
}
