{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.0.6";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-OQ+jSHtdsTZspgwoy0wrntgNX85lndH2dC3ETGiJKQg=";
  };
}
