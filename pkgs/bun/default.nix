{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.2.5";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-iPZL7e4zD/TWMo4+kMZpvHrFMUknxgT4XjKeoqHRl5s=";
  };
}
