{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.0.1";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-RmgnWTG6kTebYwIa/VAwvvJmbL+ARNC+HkbF4mJPF7o=";
  };
}
