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

    nativeBuildInputs = [
      pkgs.installShellFiles
      pypkgs.setuptools
      pypkgs.wheel
    ];
  });

  # This wrapper for pip will detect if python is called from within
  # the virtualenv: `.pythonlibs/bin`. If so, it will install a shell script
  # called `pip` into the virtualenv so that if pip is called in the future
  # python will think it's in the virtualenv.
  pip-wrapper = = pkgs.writeShellApplication {
    name = "pip-wrapper";
    text = ''
      python_location=$(which python)
      venv_pip_location="''${REPL_HOME}/.pythonlibs/bin/pip"
      venv_pip3_location="''${REPL_HOME}/.pythonlibs/bin/pip3"

      function init_venv_pip {
          cat <<EOF > "''${venv_pip_location}"
      #! /bin/sh
      export PIP_CONFIG_FILE=
      python -m pip "\$@"
      EOF
          chmod u+x "''${venv_pip_location}"
          if [ ! -f "''${venv_pip3_location}" ]; then
              ln -s "''${venv_pip_location}" "''${venv_pip3_location}"
          fi
      }

      echo "Python location is $python_location"
      if [ "$python_location" = "''${REPL_HOME}/.pythonlibs/bin/python" ]; then
          if [ ! -f "''${venv_pip_location}" ]; then
              init_venv_pip
          fi
          exec "''${venv_pip_location}" "$@"
      else
          unset PYTHONNOUSERSITE
          exec "${pip}"  "$@" 
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
  inherit config;
}
