{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.2";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.2-python-3.11.3-bundle.tgz;
  sha256 = "sha256:064s2fjhz68f830b802hc39dcanh9y5g0m1kyjhd3ffwgyrz2w4s";
  inherit python pypkgs;
}
