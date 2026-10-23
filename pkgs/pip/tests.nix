{ pkgs }:
let
  sitecustomize = pkgs.callPackage ../modules/python/sitecustomize.nix { };
  mkTest = kind: python:
    let
      legacy = import ../modules/python/pip.nix (pkgs // { pypkgs = python.pkgs; });
      pip = if kind == "legacy" then legacy.pip else python.pkgs.callPackage ./. { };
      name = "pip-user-site-${kind}-${python.pythonVersion}";
    in
    pkgs.lib.nameValuePair name (pkgs.runCommand name { } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      ${python.interpreter} ${./test_user_site.py} \
        ${pip}/bin/pip ${pip}/${python.sitePackages} \
        ${legacy.config} ${sitecustomize}
      touch "$out"
    '');
in
pkgs.lib.listToAttrs (
  map (mkTest "legacy") [ pkgs.python310 pkgs.python311 pkgs.python312 ]
  ++ map (mkTest "base") [ pkgs.python311 pkgs.python312 pkgs.python313 ]
)
