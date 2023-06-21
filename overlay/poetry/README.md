# Repl.it Custom Poetry Nix package

## Why do we need this?

We have some custom changes to:

* [Poetry](https://github.com/replit/poetry) - for some performance optimizations when
resolving what packages to fetch (avoid downloading .tar.gz source distributions and building them)
* [Pip](https://github.com/replit/pip) - for integration with our Python package cacache

Previously/currently we had an inelegent way of pre-installing these packages in the virtual environment
of the Repl in replspace. See https://replit.com/@util/Pythonify for details. Instead of this, we want to have one install path via Nix that gets these two custom programs into a Repl without
having to install them into replspace. The python Nix module will bring it all together.

## Problems

Things that make this difficult are:

* in order to prevent poetry from including its own dependencies (requests, in particular) during its operation
we need to install it inside its own virtual environment the way their [official installer](https://python-poetry.org/docs/#installing-with-the-official-installer) does. Using this workaround: https://github.com/replit/poetry/blob/replit-1.1/poetry/utils/env.py#L885 poetry can use the environment of the project for its operations, ignoring its own environment
* creating a virtual environment in replspace on behave of the user has a few downsides:
  1. somewhat slow to initialize the env ~2 second
  2. when poetry creates a virtual environment, it automatically installs a stock version
     of pip which is not our own. We'd have to add customization to poetry to override the pip version
  3. the generated environment contains a config file `pyvenv.cfg` that has a reference to the path of the
    python executable, which in our case would be coming from the `/nix/store` directory. It breaks if we use
    a different version of python with this env

## How does it work?

1. For pip (`pkgs/pip/default.nix`), we'll install it using the buildPythonPackage helper
2. For poetry:
  * we download a poetry bundle tarball from gcs which contains our version of poetry + its dependencies and then
    use pip's [offline install scheme](https://stackoverflow.com/questions/36725843/installing-python-packages-without-internet-and-using-source-code-as-tar-gz-and) to install it into a virtual env: this is how we isolate its deps away
    from the user's project deps, and how the official poetry installer does it.
    The tarball is built in the https://github.com/replit/poetry repo. See https://github.com/replit/poetry/pull/4
    for details of how it is built.
3. Inside a repl
  a. the custom pip and poetry will be made available to the user via the `PATH` variable.
  b. pip will be instructed to install packages via 
[user install mode](https://pip.pypa.io/en/stable/user_guide/#user-installs) via the `PIP_USER` variable. This is commonly used for shared Linux systems where the user does not have write access
to the system Python's site-packages directory.
  c. The `PYTHONUSERBASE` variable will tell pip where to install packages
in user mode, and we'll point it to a directory in replspace `$HOME/$REPL_SLUG/.pythonlibs`.
  d. The site package directory
within `PYTHONUSERBASE`: `$HOME/$REPL_SLUG/.pythonlibs/lib/python3.10/site-packages` is added to the `PYTHONPATH`
variable so it gets into python's module search path.
  e. `POETRY_VIRTUALENVS_CREATE` is set to false to instruct poetry not to create a virtual environment

## Known Issue

The python module way of calling poetry: `python -m poetry add requests` will no longer work, this means
UPM will need to be updated to call poetry via its binary. While we'd like this to work because there are
existing users using this technique, I don't think it's feasible if we want to isolate poetry's dependencies
away from the user project.

To allow the above would mean allowing the user to be able to `import poetry` from python. That would mean
adding poetry and its dependencies to `PYTHONPATH` or `sys.path`, which would in turn mean its resolver
would access those dependencies and treat them as belonging to the user project. Well, unless we add
further customizations to poetry...
