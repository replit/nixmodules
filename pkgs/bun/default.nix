{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.0.13";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-rOWXBvYJfhi+3fSv6ZDU5tZ51Nfy4nBIRaFOimRHHTs=";
  };
}
