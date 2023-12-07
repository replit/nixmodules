{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.0.15";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-8US2sbirFOAFXfGvHm9VqPORjUzJN/K+0/BcgK4FVcI=";
  };
}
