{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.11";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-RfP4fnTqumZKMBvC3ze4Lb7cQuUVl/czL+8xqB00kPA=";
  };
}
