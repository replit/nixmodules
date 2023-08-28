{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.1";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.1-bundle.tgz;
  sha256 = "sha256:1qh1w1dr2wvqla4cdxcgvl9xipcyk31mapivcp66v92mkvpayygk";
  inherit python pypkgs;
}
