{ pkgs, lib, ... }:
let clojure-version = lib.versions.majorMinor pkgs.clojure.version;
in
{
  id = "clojure-${clojure-version}";
  name = "Clojure Tools";
  description = ''
    Tools for working with Clojure. Includes:
    * Clojure
    * Clojure language server
  '';

  replit.runners.clojure = {
    name = "Clojure";
    language = "clojure";

    start = "${pkgs.clojure}/bin/clojure -M $file";
    fileParam = true;
  };

  replit.dev.languageServers.clojure-lsp = {
    name = "Clojure LSP";
    language = "clojure";

    start = "${pkgs.clojure-lsp}/bin/clojure-lsp";
  };
}
