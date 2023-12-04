{ fetchFromGitHub 
, mkYarnPackage
}:

mkYarnPackage {
  name = "typescript-language-server";

  src = fetchFromGitHub {
    owner = "cdmistman";
    repo = "typescript-language-server";
    rev = "d8bf621d89adeb3ef3ef7560bd59a5b648f63817";
    hash = "sha256-3bpOvDpg3AAQCmB3Cvm3IzSpFw208HZmZZvJND+Aujw=";
  };

  buildPhase = ''
    yarn build
    chmod +x deps/typescript-language-server/lib/cli.mjs
  '';
}

