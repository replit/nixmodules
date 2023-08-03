{ pkgs, python, pypkgs }:
let

  myPoetry = pkgs.stdenv.mkDerivation {
    name = "poetry-in-venv";
    version = "1.5.1";

    src = builtins.fetchTarball {
      url = https://storage.googleapis.com/poetry-bundles/poetry-1.5.1-bundle.tgz;
      sha256 = "sha256:1qh1w1dr2wvqla4cdxcgvl9xipcyk31mapivcp66v92mkvpayygk";
    };

    buildInputs = [ pypkgs.pip ];

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
myPoetry
