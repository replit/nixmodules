{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.2.2";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-P077iv0fhKwqmMBGYciYVh0dNVJ9Awy0Vx6Zt8hfUHk=";
  };
}
