{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.2.23";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-zw7QqSB5nVdv/eTgyuZtcyvyPCUwQH8m9Zx4Md/+Hw4=";
  };
}
