{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.4";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.4-python-3.8.17-bundle.tgz;
  sha256 = "sha256:061zcr31caf5p5qi7jxqz7hnw5ic26737lykd8vjs4yl4w9qsrwd";
  inherit python pypkgs;
}
