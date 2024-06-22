{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.15";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-PLGR7TEdy3sQ3S9rKWe8z8gjrmb8STyYPzbRPaJYSPI=";
  };
}