{ mkYarnPackage
, fetchFromGitHub
}:
mkYarnPackage rec {
  name = "replbox";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "replit";
    repo = "replbox";
    rev = "7f7873f2f2181ed0368aa6709218e06a4af3cc51";
    sha256 = "0bhm31rr9l2kgc44m6s2583h2ql3bg5dzham6zrxlmkfms82rg63";
  };

  packageJSON = ./package.json;
  yarnLock = ./yarn.lock;
  yarnNix = ./yarn.nix;
}
