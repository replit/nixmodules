{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.4";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.5-python-3.12.3-bundle.tgz;
  sha256 = "sha256:0d5cvh29683mya1lvwnn0r39bh3agm1gfhkrs3cc57rgs6dfp6yg";
  inherit python pypkgs;
}
