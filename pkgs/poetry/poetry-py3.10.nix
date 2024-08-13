{ pkgs, python, pypkgs }:
pkgs.callPackage ./poetry-in-venv.nix {
  version = "1.5.4";
  url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.5-python-3.10.14-bundle.tgz;
  sha256 = "sha256:0n25d8isdyjpafwrlszpsw3xi9kik24gz9b8qd9q84g9iqwxg0zp";
  inherit python pypkgs;
}
