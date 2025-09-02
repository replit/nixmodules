{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.2.21";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "[object Promise]";
  };
}
