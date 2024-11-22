{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.36";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-xSYfTX40L+cgvGpdc2sclPTfKULCJah2UsaYUYGx7Hc=";
  };
}
