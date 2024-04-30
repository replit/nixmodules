{ pkgs, lib, ... }:
let
  pyright-extended = pkgs.callPackage ../../pyright-extended { };
in
{
  id = "pyright-extended";
  name = "pyright-extended LSP";
  description = ''
    Pyright with yapf and ruff
  '';
  replit.languageServers.pyright-extended = {
    name = "pyright-extended";
    language = "python3";
    start = "${pyright-extended}/bin/langserver.index.js --stdio";
  };
}
