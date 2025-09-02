{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.2.18";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-n/HcFSSNtnmzEa4nBuzn8LuJ/IQ3/QUlTt3OO5T/ACQ=";
  };
}
