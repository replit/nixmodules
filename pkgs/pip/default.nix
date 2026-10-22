{ pip, fetchFromGitHub, flit-core }:
pip.overridePythonAttrs (old: rec {
  version = "26.2.2";
  src = fetchFromGitHub {
    owner = "pypa";
    repo = "pip";
    tag = version;
    hash = "sha256-iH5O1kneYzoHpzbfgrJc/8gVr57CNX3/xpwel4ueNqE=";
  };
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ flit-core ];
})
