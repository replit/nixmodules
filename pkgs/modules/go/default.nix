{ go, gopls }:
{ lib, ... }:
let
  goversion = lib.versions.majorMinor go.version;
in
{
  id = "go-${goversion}";
  name = "Go Tools";

  replit.packages = [
    go
  ];

  replit.dev.packages = [
    gopls
  ];

  # TODO: should compile a binary to use in deployment and not include the runtime
  replit.runners.go-run = {
    name = "go run";
    language = "go";

    start = "${go}/bin/go run $REPL_HOME";
  };

  replit.dev.formatters.go-fmt = {
    name = "go fmt";
    language = "go";
    displayVersion = "Go ${go.version}";

    start = "${go}/bin/go fmt";
    stdin = false;
  };

  replit.dev.languageServers.gopls = {
    name = "gopls";
    language = "go";

    displayVersion = gopls.version;

    start = "${gopls}/bin/gopls";
  };
}
