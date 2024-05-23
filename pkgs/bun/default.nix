{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.8";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-JuDT+8FHbamdMVCDeSTGPYOvhPY2EZ9XeD2zjHEj36Y=";
  };
}
