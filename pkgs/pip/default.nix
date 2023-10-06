{ pkgs, pypkgs }:
pypkgs.buildPythonPackage rec {
  pname = "pip";
  version = "21.2.dev0";
  format = "other";

  src = pkgs.fetchFromGitHub {
    owner = "replit";
    repo = pname;
    rev = "21.2.dev0";
    sha256 = "sha256-kSjKeLqXUG91QncrQlqqCWZvnnNnDuhk1jLBRtu7xdw=";
    name = "${pname}-${version}-source";
  };

  nativeBuildInputs = [ pypkgs.bootstrapped-pip ];

  # pip detects that we already have bootstrapped_pip "installed", so we need
  # to force it a little.
  pipInstallFlags = [ "--ignore-installed" ];

  # Pip wants pytest, but tests are not distributed
  doCheck = false;

  meta = {
    description = "The PyPA recommended tool for installing Python packages";
    license = with pkgs.lib.licenses; [ mit ];
    homepage = "https://github.com/replit/pip";
  };
}
