{ go }:
{ pkgs, lib, ... }:
let
  goversion = lib.versions.majorMinor go.version;
in
{
  id = "go-${goversion}";
  name = "Go Tools";

  packages = [
    go
  ];

  replit.runners.go-run = {
    name = "go run";
    language = "go";

    start = "${go}/bin/go run $file";
    fileParam = true;
  };

  replit.formatters.go-fmt = {
    name = "go fmt";
    language = "go";

    start = "${go}/bin/go fmt";
    stdin = false;
  };

  replit.languageServers.gopls = {
    name = "gopls";
    language = "go";

    start = "${pkgs.gopls}/bin/gopls";
  };
}
