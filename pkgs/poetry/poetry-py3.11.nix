{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.6";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.6-python-3.11.10-bundle.tgz;
  sha256 = "sha256:139kfql4in5lc519q6bfby27jbfaixm4x1zdj778vm1hdd8ydn6k";
  inherit python pypkgs;
}
