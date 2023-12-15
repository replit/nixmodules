{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.3";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.3-python-3.10.11-bundle.tgz;
  sha256 = "sha256:10jh59xcj0yx9hh97w47ixr1np7szw9y62zxqy9phzpk6yc2qm68";
  inherit python pypkgs;
}
