{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.0.23";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-IPQ4W8B4prlLljf7OviGpYtqNxSxMB1kHCMOrnbxldw=";
  };
}
