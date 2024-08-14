{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.24";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-9HiIBnjPKC/dpGzJ1Y4goN3h+tjJz+4Sjq1DmWRT4cg=";
  };
}
