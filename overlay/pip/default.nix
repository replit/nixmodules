{ fetchFromGitHub, lib, pythonPackages }:
pythonPackages.buildPythonPackage rec {
  pname = "pip";
  version = "21.2.dev0";
  format = "other";

  src = fetchFromGitHub {
    owner = "replit";
    repo = pname;
    rev = "main";
    sha256 = "sha256-k4RnK9TnvfJlxpihdHFg3JmYtNDC4KY+f41VwJ+e+1A=";
    name = "${pname}-${version}-source";
  };

  nativeBuildInputs = [ pythonPackages.bootstrapped-pip ];

  # pip detects that we already have bootstrapped_pip "installed", so we need
  # to force it a little.
  pipInstallFlags = [ "--ignore-installed" ];

  # Pip wants pytest, but tests are not distributed
  doCheck = false;

  meta = {
    description = "The PyPA recommended tool for installing Python packages";
    license = with lib.licenses; [ mit ];
    homepage = "https://github.com/replit/pip";
  };
}
