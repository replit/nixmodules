{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.21";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-KPq1T0jxN6ghFIoKRe3rQqUtI6qMuRdMzIFVSj+JMco=";
  };
}
