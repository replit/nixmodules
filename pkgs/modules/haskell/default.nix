{ pkgs, lib, ... }:
let
  ghc-version = lib.versions.majorMinor pkgs.ghc.version;
in
{
  id = "haskell-ghc${ghc-version}";
  name = "Haskell Tools";
  displayVersion = ghc-version;
  description = ''
    Haskell development tools. Includes GHCi - Glasgow Haskell Compiler, and Haskell language server.
  '';

  replit.packages = with pkgs; [
    ghc
  ];

  replit.runners.runghc = {
    name = "GHC app";
    language = "haskell";

    start = "${pkgs.ghc}/bin/runghc $file";
    fileParam = true;
  };

  # TODO: allow users to select runners
  # replit.runners.ghci = {
  #   name = "ghci";
  #   language = "haskell";

  #   start = "${pkgs.ghc}/bin/ghci $file";
  #   fileParam = true;
  #   interpreter = true;
  # };

  replit.dev.languageServers.haskell-language-server = {
    name = "Haskell Language Server";
    language = "haskell";

    start = "${pkgs.haskellPackages.haskell-language-server}/bin/haskell-language-server --lsp";
  };
}
