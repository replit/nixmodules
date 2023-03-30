{ pkgs, ... }:
{
  name = "GoTools";
  version = "1.0";

  packages = with pkgs; [
    go
    gopls
  ];

  replit.runners.go-run = {
    name = "go run";
    language = "go";

    start = "${pkgs.go}/bin/go run $file";
    fileParam = true;
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
