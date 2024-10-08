{ pkgs, lib, ... }:
{
  id = "pyright";
  name = "pyright LSP";
  displayVersion = pkgs.pyright.version;
  description = ''
    Pyright is a full-featured, standards-based static type checker for Python. It is designed for high performance and can be used with large Python source bases.
  '';
  replit.dev.languageServers.pyright = {
    name = "pyright";
    displayVersion = pkgs.pyright.version;
    language = "python3";
    start = "${pkgs.pyright}/bin/pyright-langserver --stdio";
  };

  replit.env = {
    PATH = "${pkgs.pyright}/bin";
  };
}
