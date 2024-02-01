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
    # Determine how many vcpus we have, first in the standard location, with a fallback
    # to the cgroup info, since resources.json does not exist during Deployments.
    if [ -e /repl/stats/resources.json ]; then  # Common resources location
      numVCpu="$(${pkgs.jq}/bin/jq .numVCpu </repl/stats/resources.json)"
    else
      cgroup_path="$(cut -f 3 -d : < /proc/1/cgroup)"
      if [ -f "$cgroup_path" ]; then
        cpu_path="/sys/fs/cgroup/$cgroup_path/cpu.max"
        if [ -f "$cpu_path" ]; then
          numVCpu="$(${pkgs.jq}/bin/jq -R 'split(" ") | map(tonumber) | .[0] / .[1]' < "$cpu_path")"
        fi
      fi
    fi

    # If we can't determine numVCpu, presume 0.5 to help free users.
    if [ "''${numVCpu:-0.5}" = "0.5" ]; then
    # Don't run multiple install workers in parallel if we have only 0.5 CPUs:
    # helps with speed in free accounts
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
