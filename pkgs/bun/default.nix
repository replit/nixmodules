{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.2.16";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-+DEdjXyqDZOMbEzs8KYA5enOTidaQR44oun4x30MEAI=";
  };
}
