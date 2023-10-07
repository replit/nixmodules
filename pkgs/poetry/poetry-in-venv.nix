{ pkgs, python, pypkgs, version, url, sha256 }:
let pip = pypkgs.pip.overridePythonAttrs
  (old: rec {
    doCheck = false;
  });
in
pkgs.stdenv.mkDerivation {
  name = "poetry-in-venv";
  inherit version;

  src = builtins.fetchTarball {
    inherit url sha256;
  };
  

  buildInputs = [
    pip
  ];

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
}
