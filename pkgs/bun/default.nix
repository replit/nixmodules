{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.2.12";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-MzeWT6ox2LzhmfkXCBMHEO8ucLmP80o09ZCxdFiApjM";
  };
}
