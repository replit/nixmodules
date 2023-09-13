{ pkgs, lib, ... }:
let
  goversion = lib.versions.majorMinor pkgs.go.version;
in
{
  id = "go-${goversion}";
  name = "Go Tools";

  packages = with pkgs; [
    go
    gopls
  ];

  replit.runners.go-run = {
    name = "go run";
    language = "go";

    start = "${pkgs.go}/bin/go run $REPL_HOME";
  };

  replit.formatters.go-fmt = {
    name = "go fmt";
    language = "go";

    start = "${pkgs.go}/bin/go fmt";
    stdin = false;
  };

  replit.languageServers.gopls = {
    name = "gopls";
    language = "go";

    start = "${pkgs.gopls}/bin/gopls";
  };
}
