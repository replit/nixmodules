{ pkgs, python, pypkgs, version, url, sha256 }:
let
  poetry = pkgs.stdenv.mkDerivation {
    name = "poetry-in-venv";
    inherit version;

    src = builtins.fetchTarball {
      inherit url sha256;
    };

    installPhase = ''
      mkdir -p $out/bin
      ${python}/bin/python3 -m venv $out/env
      touch $out/env/poetry_env # This allows poetry to recognize it
                                # https://github.com/replit/poetry/blob/replit-1.1/poetry/utils/env.py#L885
                                # invoking the workaround so that poetry
                                # does not use its own venv for the project
                                # env
      $out/env/bin/pip install poetry --find-links ./ --no-index
      ln -s $out/env/bin/poetry $out/bin/poetry
    '';
  };
in
pkgs.writeShellScriptBin "poetry" ''
  # Don't run multiple install workers in parallel if we have only 0.5 CPUs:
  # helps with speed in free accounts
  numVCpu=$(cat /repl/stats/resources.json | ${pkgs.jq}/bin/jq .numVCpu)
  if [ "''${numVCpu}" = "0.5" ]; then
    export POETRY_INSTALLER_PARALLEL="0"
  fi
  ${poetry}/bin/poetry $@
''
