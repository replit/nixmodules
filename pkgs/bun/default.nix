{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.30";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-UGDyM+7L7YGXaGs3sOstqP9SKC9XvR3Y45T1Ov3shA4=";
  };
}
