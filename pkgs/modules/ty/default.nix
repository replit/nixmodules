{ pkgs, lib, ... }:
{
  id = "ty";
  name = "ty LSP";
  displayVersion = pkgs.ty.version;
  description = ''
    Ty is an extremely fast Python type checker from Astral with an integrated language server.
  '';
  replit.dev.languageServers.ty = {
    name = "ty";
    displayVersion = pkgs.ty.version;
    language = "python3";
    start = "${pkgs.ty}/bin/ty server";
  };

  replit.env = {
    PATH = "${pkgs.ty}/bin";
  };
}
