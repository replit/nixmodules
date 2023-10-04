{ pkgs, lib, ... }:
let
  goversion = lib.versions.majorMinor pkgs.go.version;
in
{
  id = "go-${goversion}";
  name = "Go Tools";

  replit.packages = with pkgs; [
    go
  ];

  replit.dev.packages = [
    pkgs.gopls
  ];

  # TODO: should compile a binary to use in deployment and not include the runtime
  replit.runners.go-run = {
    name = "go run";
    language = "go";

    start = "${pkgs.go}/bin/go run $REPL_HOME";
  };

  replit.dev.formatters.go-fmt = {
    name = "go fmt";
    language = "go";

    start = "${pkgs.go}/bin/go fmt";
    stdin = false;
  };

  replit.dev.languageServers.gopls = {
    name = "gopls";
    language = "go";

    start = "${pkgs.gopls}/bin/gopls";
  };
}
