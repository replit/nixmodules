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
                                # https://github.com/replit/poetry/blob/replit-1.5/src/poetry/utils/env.py#L1154
                                # invoking the workaround so that poetry
                                # does not use its own venv for the project
                                # env
      $out/env/bin/pip install poetry --find-links ./ --no-index
      ln -s $out/env/bin/poetry $out/bin/poetry
    '';
  };
in
pkgs.writeShellApplication {
  name = "poetry";
  text = ''
    # Don't run multiple install workers in parallel if we have only 0.5 CPUs:
    # helps with speed in free accounts
    numVCpu=$(${pkgs.jq}/bin/jq .numVCpu </repl/stats/resources.json)
    if [ "''${numVCpu}" = "0.5" ]; then
    export POETRY_INSTALLER_PARALLEL="0"
    fi
    # Temporarily work around upm locking infrastructute being very slow
    # In replit, poetry is not currently configured in such a way that this
    # would ever print any virtualenv paths.
    if [ "$1" = env ] && [ "$2" = list ]; then
      exit 0
    fi
    ${poetry}/bin/poetry "$@"
  '';
}
