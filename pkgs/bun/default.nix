{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.14";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-LCfBxZMR+DI9HDvk3ZCJGFPtev+4U9AcxY/qDYbpOuA=";
  };
}