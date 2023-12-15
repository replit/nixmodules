{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.2";
  url = "https://storage.googleapis.com/poetry-bundles/poetry-1.5.2-python-3.8.17-bundle.tgz";
  sha256 = "sha256:1qzays4q93h85p9g1zq5d1xj6c19nk1m3gd58wfpdf5d0y373pvf";
  inherit python pypkgs;
}
