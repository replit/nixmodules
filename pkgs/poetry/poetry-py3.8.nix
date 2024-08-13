{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.5";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.5-python-3.8.18-bundle.tgz;
  sha256 = "sha256:0iaw6iyj5skbi2vs5sfcbwlncxjfq3i2k1nnfvrdc02ybbmpbl3q";
  inherit python pypkgs;
}
