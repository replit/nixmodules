{ pkgs, ... }:
# Use this sitecustomize.py (a directory containing it in PYTHONPATH) to
# overwrite pip's shebang line treatment so it doesn't use hard-coded paths
# to the python executable, so we could update Python without editing Repls
# Using this approach also allows this scheme to work with a version of pip
# which the user has installed into their .pythonlibs, which can happen if they
# upgrade pip.
pkgs.writeTextFile {
  name = "sitecustomize";
  text = builtins.readFile ./sitecustomize.py;
  destination = "/lib/python3/site-packages/sitecustomize.py";
}
