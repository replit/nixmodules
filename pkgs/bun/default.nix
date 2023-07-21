{ lib
, stdenvNoCC
, fetchurl
, autoPatchelfHook
, unzip
, openssl
}:

stdenvNoCC.mkDerivation rec {
  version = "0.6.14";
  pname = "bun";

  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    sha256 = "5iU+1FevTjjzo/qN0zjIoCQflbWCmdfMXkx+6BOEEcc=";
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
