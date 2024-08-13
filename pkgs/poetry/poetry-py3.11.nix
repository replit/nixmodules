{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.4";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.5-python-3.11.9-bundle.tgz;
  sha256 = "sha256:0madgivk9zywddir130rrvfyxg8whah8dgzd1g2m88j1yvdgspnd";
  inherit python pypkgs;
}
