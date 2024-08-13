{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.4";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.5-python-3.9.19-bundle.tgz;
  sha256 = "sha256:0gmkb35nqym09lshk5r51zhr2l609ag4aahqbh43pckqjqw80446";
  inherit python pypkgs;
}
