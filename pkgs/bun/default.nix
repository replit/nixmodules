{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.13";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-QC6dsWjRYiuBIojxPvs8NFMSU6ZbXbZ9Q/+u+45NmPc=";
  };
}
