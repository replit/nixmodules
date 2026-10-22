{ zig, zls }:
{ lib, ... }:
let
  version = lib.versions.majorMinor zig.version;
  language = "zig";
  extensions = [ ".zig" ];
in
{
  id = "zig-${version}";
  name = "zig";
  displayVersion = "0";

  replit = {
    runners.zig-build-run = {
      name = "zig build run";
      inherit language extensions;
      fileParam = false;
      start = "${zig}/bin/zig build run";
    };

    dev = {
      packages = [ zig ];
      formatters.zig-fmt = {
        name = "zig fmt";
        inherit language extensions;
        start = "${zig}/bin/zig fmt $file";
        stdin = false;
      };
      languageServers.zls = {
        name = "zls";
        inherit language extensions;
        start = "${zls}/bin/zls";
      };
    };
  };
}
