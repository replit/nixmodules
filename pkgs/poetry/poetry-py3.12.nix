{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.4";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.5-python-3.12.3-bundle.tgz;
  sha256 = "0xvlvg2ydkhggnqxzq2ximl5b5l2jr10gqkgi9w5763w7yys1lk3";
  inherit python pypkgs;
}
