{ pkgs, lib, ... }:
let
  inherit (pkgs) clojure;

  clojure-version = lib.versions.majorMinor clojure.version;
in
{
  id = "clojure-${clojure-version}";
  name = "Clojure Tools";

  packages = [
    clojure
  ];

  replit.runners.clojure = {
    name = "Clojure";
    language = "clojure";

    start = "${clojure}/bin/clojure -M $file";
    fileParam = true;
  };

  replit.languageServers.clojure-lsp = {
    name = "Clojure LSP";
    language = "clojure";

    start = "${pkgs.clojure-lsp}/bin/clojure-lsp";
  };
}
