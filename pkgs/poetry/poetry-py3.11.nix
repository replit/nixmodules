{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.2";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.2-python-3.11.3-bundle.tgz;
  sha256 = "sha256:0z6z5aajd2mqy8h922fs7m2zpgyjqr8252dgvz8zjsyhq7bww05s";
  inherit python pypkgs;
}
