{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.6";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.6-python-3.10.16-bundle.tgz;
  sha256 = "sha256:1bgdqyh7mvbpay47k5wni25vrx7j9f3g15bhcnws33vy2vyqyldc";
  inherit python pypkgs;
}
