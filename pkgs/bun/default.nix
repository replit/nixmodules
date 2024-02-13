{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.0.26";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-mWVe8BFGSXKJYnr2QXZah1XYfir5zN5+2wQ4HfgdOyE=";
  };
}
