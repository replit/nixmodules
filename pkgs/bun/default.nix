{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.44";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-CzXRBAm5UTotBknu4/jRTUn8ROHa6GLt1dcyZDFQAZM=";
  };
}
