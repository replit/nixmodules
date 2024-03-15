{ pkgs, lib, ... }:
let
  ghc-version = lib.versions.majorMinor pkgs.ghc.version;
in
{
  id = "haskell-ghc${ghc-version}";
  name = "Haskell Tools";

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
    displayVersion = pkgs.haskellPackages.haskell-language-server.version;

    start = "${pkgs.haskellPackages.haskell-language-server}/bin/haskell-language-server --lsp";
  };
}
