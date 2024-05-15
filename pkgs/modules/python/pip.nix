pkgs @ { pypkgs, ... }:

let
  pip = pypkgs.pip.overridePythonAttrs (old: rec {
    outputs = [
      "out"
    ];
    # Skip building the docs for pip because that was failing
    # with a sphinx-build error with a version of nixpkgs-unstable for 3.10 (worked for >3.11)
    # and we don't need the docs
    postBuild = "";
    postInstall = "";
  });

  config = pkgs.writeTextFile {
    name = "pip.conf";
    text = ''
      [global]
      user = yes
      disable-pip-version-check = yes
      break-system-packages = yes
    '';
  };
in
{
  inherit pip config;
}
