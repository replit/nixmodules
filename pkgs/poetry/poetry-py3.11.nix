{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.1";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.1-python-3.11.3-bundle.tgz;
  sha256 = "sha256:0sww716n5i65qf5rjp66kr8nbkv3wa6id2cyf2ncv5zqpnyg1nw2";
  inherit python pypkgs;
}
