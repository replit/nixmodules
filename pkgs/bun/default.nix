{ bun
, fetchurl
}:

bun.overrideAttrs rec {
  version = "1.1.40";
  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-n5BFNl4hxkZWiWZ8GLFpUZxQYh2+VbCQjidFyAqhMQI=";
  };
}
