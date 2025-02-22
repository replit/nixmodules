{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.2.3";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-wNNfzF/rCOi4SDLr5hcS0r+x8Rgd5wbpOHvBLiNGPzU=";
  };
}
