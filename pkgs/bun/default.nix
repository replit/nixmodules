{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.37";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-zHpTkX7cm2V3i6zfyiHprPvR8vaXQtYWmAN3p4Yg6XQ=";
  };
}
