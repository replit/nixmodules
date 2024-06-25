{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.17";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-pRggu/l0HgCk73kX7W43qKFVE13/7pP4P9bTiqyK2Yk=";
  };
}