{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.0.16";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-2f/n/aKJO2LnCWohYSQ3zukuXZ+cKFzem+mKeYQnoTc=";
  };
}
