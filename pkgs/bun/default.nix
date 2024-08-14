{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.23";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-6b+X+ynbkECEOFssPUhiEiKOQDZ4xydZp5Ewd5kFAhY=";
  };
}
