{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.4";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.5-python-3.11.9-bundle.tgz;
  sha256 = "sha256:153i36hhpnyr5wj4x0klfmzsxakmi1hmsahppd7q0mf0fchdlgwx";
  inherit python pypkgs;
}
