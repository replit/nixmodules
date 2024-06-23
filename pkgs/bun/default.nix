{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.16";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-6Cufy76EpnpMDCJGVxIZ0WtfALD6iRko7+NThJG9v5Y=";
  };
}