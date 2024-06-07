{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.4";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.4-python-3.9.19-bundle.tgz;
  sha256 = "sha256:134n1avv3adc3ypvd0hd4mkrkfdbb70qz8l1j0sx2q6h48nnb0pc";
  inherit python pypkgs;
}
