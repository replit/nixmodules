{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.1";
  url = "https://storage.googleapis.com/poetry-bundles/poetry-1.5.1-python-3.8.15-bundle.tgz";
  sha256 = "sha256:0j25p10msnzxm75gc4q132ndj9j2igwqhkiy4bmidxp2dlrzxqmc";
  inherit python pypkgs;
}
