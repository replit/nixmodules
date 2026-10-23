{ pip, fetchFromGitHub, flit-core }:
pip.overridePythonAttrs (old: rec {
  # The module installs into PYTHONUSERBASE; pip rejects --user when its wrapper disables it.
  permitUserSite = true;
  version = "26.2.2";
  src = fetchFromGitHub {
    owner = "pypa";
    repo = "pip";
    tag = version;
    hash = "sha256-iH5O1kneYzoHpzbfgrJc/8gVr57CNX3/xpwel4ueNqE=";
  };
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ flit-core ];
})
