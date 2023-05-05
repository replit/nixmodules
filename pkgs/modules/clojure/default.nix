{ pkgs, lib, ... }: {
  id = "clojure";
  name = "Clojure Tools";
  community-version = lib.versions.majorMinor pkgs.clojure.version;
  version = "1.0";

  replit.runners.clojure = {
    name = "Clojure";
    language = "clojure";

    start = "${pkgs.clojure}/bin/clojure -M $file";
    fileParam = true;
  };

  replit.languageServers.clojure-lsp = {
    name = "Clojure LSP";
    language = "clojure";

    start = "${pkgs.clojure-lsp}/bin/clojure-lsp";
  };
}
