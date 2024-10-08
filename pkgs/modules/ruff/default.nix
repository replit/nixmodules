{ pkgs, lib, ... }:
{
  id = "ruff";
  name = "ruff LSP";
  displayVersion = pkgs.ruff.version;
  description = ''
    A Language Server Protocol implementation for Ruff, an extremely fast Python linter and code formatter, written in Rust.

    Ruff can be used to replace Flake8 (plus dozens of plugins), Black, isort, pyupgrade, and more, all while executing tens or hundreds of times faster than any individual tool.
  '';
  replit.dev.languageServers.ruff = {
    name = "ruff";
    displayVersion = pkgs.ruff.version;
    language = "python3";
    start = "${pkgs.ruff}/bin/ruff server";
  };

  replit.env = {
    PATH = "${pkgs.ruff}/bin";
  };
}
