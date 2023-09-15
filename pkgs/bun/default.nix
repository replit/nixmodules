{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.0.2";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-kHv8PU48Le4lG3pf304hXggAtx/I5uBeu4aHmLsbdgw=";
  };
}
