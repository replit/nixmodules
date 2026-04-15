# Poetry packaging

We now use upstream nixpkgs Poetry directly instead of the old Replit fork and
prebuilt bundle tarballs.

## How it works

`pkgs/poetry/default.nix` keeps a thin wrapper around nixpkgs `poetry` for two
reasons:

* build Poetry against the same Python minor version as the module's project
  Python via `pkgs.poetry.override { python3 = python; }`
* keep the low-vCPU installer parallelism guard we already use in Repls

The Python module still sets `POETRY_VIRTUALENVS_CREATE=0`, `PYTHONUSERBASE`,
and `PATH` so Poetry installs into `.pythonlibs` in the same place as pip.

## Add a new Python version

No Poetry bundle needs to be generated anymore. Adding a new Python version only
requires wiring the new `python` / `pypkgs` pair into the relevant module.
