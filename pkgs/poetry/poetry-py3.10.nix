{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.2";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.2-python-3.10.11-bundle.tgz;
  sha256 = "sha256:0gs851h7sjcwr1yn9fz7sj6022jlp4k0vjlgwiv9fh7bdqw7xx9j";
  inherit python pypkgs;
}
