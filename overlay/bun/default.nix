{ lib
, stdenvNoCC
, fetchurl
, autoPatchelfHook
, unzip
, openssl
}:

stdenvNoCC.mkDerivation rec {
  version = "0.6.7";
  pname = "bun";

  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    sha256 = "bX3gV3wR2ZJabP6LXT4Tg3T+061aghktXD2YOrQfmWo=";
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
