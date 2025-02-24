{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.6";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.6-python-3.12.7-bundle.tgz;
  sha256 = "sha256:1v42fgq3p5g41l5al33fswrx4g335gf1jxadvdf378giy583r309";
  inherit python pypkgs;
}
