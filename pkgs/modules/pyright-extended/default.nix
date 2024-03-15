{ pkgs, lib, ... }:
let
  pyright-extended = pkgs.callPackage ../../pyright-extended { };
in
{
  id = "pyright-extended";
  name = "pyright-extended LSP";
  replit.languageServers.pyright-extended = {
    name = "pyright-extended";
    language = "python3";
    displayVersion = pyright-extended.version;
    start = "${pyright-extended}/bin/langserver.index.js --stdio";
  };
}
