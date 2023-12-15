{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.3";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.3-python-3.11.3-bundle.tgz;
  sha256 = "sha256:0vrpl5izgmz3g5ihk5wkm2lswaxsffp3w153xg3ssfnq47xzc0p4";
  inherit python pypkgs;
}
