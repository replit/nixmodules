{ pkgs, pypkgs }:
pypkgs.buildPythonPackage rec {
  pname = "python-lsp-server";
  version = "1.15.9";
  format = "pyproject";

  src = pkgs.fetchFromGitHub {
    owner = "replit";
    repo = "python-lsp-server";
    rev = "develop";
    hash = "sha256-DUs01BYTrlwmRt+sMeCGnIHV9NSS2m3XLkXAfaQ/Xxw=";
  };

  SETUPTOOLS_SCM_PRETEND_VERSION = version;

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace "--cov-report html --cov-report term --junitxml=pytest.xml" "" \
      --replace "--cov pylsp --cov test" ""
  '';

  pythonRelaxDeps = [
    "autopep8"
    "flake8"
    "mccabe"
    "pycodestyle"
    "pydocstyle"
    "pyflakes"
  ];

  nativeBuildInputs = [
    pypkgs.pythonRelaxDepsHook
    pypkgs.setuptools-scm
  ];

  propagatedBuildInputs = with pypkgs; [
    docstring-to-markdown
    jedi
    pluggy
    python-lsp-jsonrpc
    setuptools # `pkg_resources`imported in pylsp/config/config.py
    ujson
    toml
    whatthepatch

    # extras
    yapf
    pyflakes
    rope
    # autopep8
    # flake8
    # mccabe
    # pycodestyle
    # pydocstyle
    # pyflakes
    # pylint
  ];

  doCheck = false;

  pythonImportsCheck = [
    "pylsp"
    "pylsp.python_lsp"
  ];

  meta = with pkgs.lib; {
    description = "Python implementation of the Language Server Protocol";
    homepage = "https://github.com/replit/python-lsp-server";
    license = licenses.mit;
  };
}
