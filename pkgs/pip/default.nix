# TODO: figure out cacahing again.
# The way our pip fork works is by symlinking files into the repl.
# Unfortunately, this breaks when installing packages that rely on some non-py
# files. For example, Django sometimes expects to be able to import a `.tgz`
# file, which it resolves relative to the location of a certain file. Since we
# symlinked the file, it looks for the `.tgz` file in the content-addressed
# directory, which doesn't have the file (due to being content-addressed!).
# See https://linear.app/replit/issue/DX-297/nix-modules-breaks-django-within-python-repls
# and follow-up conversation in https://replit.slack.com/archives/C03KS2B221W/p1698771124823679
# for more information.
# Known-broken packages:
# - Django (`common-passwords.tgz`)
# - opencv-python

{ pkgs, pypkgs }:
pypkgs.buildPythonPackage rec {
  pname = "pip";
  version = "21.2.dev0";
  format = "other";

  src = pkgs.fetchFromGitHub {
    owner = "replit";
    repo = pname;
    rev = "21.2.dev0";
    sha256 = "sha256-k4RnK9TnvfJlxpihdHFg3JmYtNDC4KY+f41VwJ+e+1A=";
    name = "${pname}-${version}-source";
  };

  nativeBuildInputs = [ ];

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
