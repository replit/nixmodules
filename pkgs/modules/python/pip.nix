pkgs @ { pypkgs, python, ... }:

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

    nativeBuildInputs = [
      pkgs.installShellFiles
      pypkgs.setuptools
      pypkgs.wheel
    ];
  });

  # This pip wrapper will detect if python is called from within
  # the virtualenv: `.pythonlibs`. If so, it will simply call `python -m pip ...`
  pip-wrapper = pkgs.writeShellApplication {
    name = "pip";
    text = ''
      python_location=$(which python)

      if [ "$python_location" = "''${REPL_HOME}/.pythonlibs/bin/python" ]; then
        exec python -m pip "$@"
      else
        unset PYTHONNOUSERSITE
        exec "${pip}/bin/pip"  "$@" 
      fi
    '';
  };

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
  pip = pip-wrapper;
  sitePackages = "${pip}/${python.sitePackages}";
  inherit config;
}
