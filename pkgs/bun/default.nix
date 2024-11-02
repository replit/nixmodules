{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.34";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-S8AA/1CWxTSHZ60E2ZNQXyEAOalYgCc6dte9CvD8Lx8=";
  };
}
