{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.2";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.2-python-3.10.11-bundle.tgz;
  sha256 = "sha256:0qabdvan0f2fidy9czdlhbl7j3wsnsqkjnwblq52ljlbzrgnp9ba";
  inherit python pypkgs;
}
