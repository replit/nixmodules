{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.1";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.1-python-3.12.0-bundle.tgz;
  sha256 = "sha256:0kkifv6zg4qvjrnc0sf2is4r4dlgckxd60hyfh689710yphqskad";
  inherit python pypkgs;
}
