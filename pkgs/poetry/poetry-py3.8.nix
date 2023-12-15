{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.3";
  url = "https://storage.googleapis.com/poetry-bundles/poetry-1.5.3-python-3.8.17-bundle.tgz";
  sha256 = "sha256:0vazh05z7zfwbgbykq6xaba6dkfhvspf9rikpvqnnic5v7izm502";
  inherit python pypkgs;
}
