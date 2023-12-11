{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.2";
  url = "https://storage.googleapis.com/poetry-bundles/poetry-1.5.2-python-3.8.17-bundle.tgz";
  sha256 = "sha256:14bgmas1qnkk0ndisphn2ciidffi7mpmd3hibzbs1as8hpwpkw5m";
  inherit python pypkgs;
}
