{ pkgs, pruneVersion, ... }: {
  id = "haskell";
  name = "Haskell Tools";
  community-version = pruneVersion pkgs.ghc.version;
  version = "1.0";

  packages = with pkgs; [
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

  replit.languageServers.haskell-language-server = {
    name = "Haskell Language Server";
    language = "haskell";

    start = "${pkgs.haskell-language-server}/bin/haskell-language-server --lsp";
  };
}
