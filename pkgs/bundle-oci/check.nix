{ pkgs }:

let
  dependency = pkgs.runCommand "bundle-oci-dependency" { } ''
    mkdir -p "$out"
    printf 'dependency\n' > "$out/data"
    ln "$out/data" "$out/hardlink"
  '';
  module = pkgs.runCommand "bundle-oci-module" { } ''
    mkdir -p "$out/bin"
    printf '%s\n' '${dependency}' > "$out/module.json"
    printf '#!/bin/sh\nexit 0\n' > "$out/bin/tool"
    chmod 755 "$out/bin/tool"
    ln -s ../module.json "$out/bin/relative"
    ln -s '${dependency}/data' "$out/absolute"
  '';
  bundle = (pkgs.callPackage ../bundle {
    self = { modules.fixture = module; };
  }) { };
  image = pkgs.callPackage ./. { inherit bundle; };
  closure = pkgs.closureInfo { rootPaths = [ bundle ]; };
in
pkgs.runCommand "bundle-oci-check"
{
  nativeBuildInputs = [ pkgs.erofs-utils pkgs.python3 ];
}
  ''
    python3 ${./check.py} ${image} ${bundle} ${closure}/store-paths ${dependency}
    touch "$out"
  ''
