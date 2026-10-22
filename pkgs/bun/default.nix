{ bun
, fetchurl
}:

# ponytail: x86_64-linux module outputs; add platform sources if module outputs expand.
bun.overrideAttrs rec {
  version = "1.4.3";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-PnMFKNiXdfA/h/BcBnh8TfQJnQo38/JS57gpyyOBbhg=";
  };
}
