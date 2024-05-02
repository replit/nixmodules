{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.6";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-IzjuIPXljt8EStcRdGj55SWIpqJdGQeVZVAS5u9sW+Y=";
  };
}
