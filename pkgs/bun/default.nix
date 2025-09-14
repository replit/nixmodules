{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.2.22";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-TERq8aAde0Dh4RuuvDUvmyv9Eoh+Ubl907WYec7idDo=";
  };
}
