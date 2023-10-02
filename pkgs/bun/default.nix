{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.0.3";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-8xMBU3jloMsdekejKrnswWfzXhxwvsHFNgcUf4hn0W4=";
  };
}
