def pip_build_shebang(self, executable, post_interp):
    import os, sys

    if os.name != "posix":
        simple_shebang = True
    else:
        # Add 3 for '#!' prefix and newline suffix.
        shebang_length = len(executable) + len(post_interp) + 3
        if sys.platform == "darwin":
            max_shebang_length = 512
        else:
            max_shebang_length = 127
        simple_shebang = (b" " not in executable) and (
            shebang_length <= max_shebang_length
        )

    if simple_shebang:
        result = b"#!/usr/bin/env python3" + post_interp + b"\n"
    else:
        result = b"#!/bin/sh\n"
        result += b"'''exec' python3" + post_interp + b' "$0" "$@"\n'
        result += b"' '''"
    return result


def pip_should_patch():
    import sys

    exe = sys.argv[0]
    argv0_pip = (
        exe.endswith("/pip") or exe.endswith("/pip3") or exe.endswith("/.pip-wrapped")
    )
    maybe_pip = sys.argv[0:2] == ["-m", "install"]
    return argv0_pip or maybe_pip


def pip_patch():
    from pip._vendor.distlib.scripts import ScriptMaker

    ScriptMaker._build_shebang = pip_build_shebang


def venv_setup_scaffolding(pythonlibs):
    import os

    lib64 = os.path.join(pythonlibs, "lib64")
    os.makedirs(os.path.join(pythonlibs, "bin"), exist_ok=True)
    os.makedirs(os.path.join(pythonlibs, "include"), exist_ok=True)
    os.makedirs(os.path.join(pythonlibs, "lib"), exist_ok=True)
    if not os.path.exists(lib64):
        os.symlink("lib", lib64)


def venv_setup_pyvenv_cfg(pythonlibs, real_executable):
    import os, sys

    pyvenv_cfg = os.path.join(pythonlibs, "pyvenv.cfg")
    cfg_exists = os.path.exists(pyvenv_cfg)
    mode = "r+" if cfg_exists else "w"
    home = None
    includeSSP = None
    version = None
    with open(pyvenv_cfg, mode) as handle:
        if cfg_exists:
            for line in handle.readlines():
                [k, v] = line.split("=", 1)
                k = k.strip()

                if k == "home":
                    home = v.strip()
                elif k == "include-system-site-packages":
                    includeSSP = v.strip()
                elif k == "version":
                    version = v.strip()

        if home is None:
            home = os.path.dirname(real_executable)
            print(f"home = {home}", file=handle)
        if version is None:
            major = sys.version_info.major
            minor = sys.version_info.minor
            micro = sys.version_info.micro
            version = f"{major}.{minor}.{micro}"
            print(f"version = {version}", file=handle)
            # What happens in the case of mismatch?
            # Presumably need to rewrite the whole file.
            # For now, ignore.
        if includeSSP is None:
            includeSSP = "true"
            print(f"include-system-site-packages = {includeSSP}", file=handle)


def venv_iterate_variants(pythonlibs):
    import os, sys

    major = sys.version_info.major
    minor = sys.version_info.minor
    bin_path = os.path.join(pythonlibs, "bin")
    for variant in ["python", f"python{major}", f"python{major}.{minor}"]:
        yield variant, os.path.join(bin_path, variant)


def venv_setup_python_links(pythonlibs, real_executable):
    import os

    for _, variant_path in venv_iterate_variants(pythonlibs):
        if os.path.exists(variant_path):
            if os.readlink(variant_path) != real_executable:
                os.remove(variant_path)
        if not os.path.exists(variant_path):
            os.symlink(real_executable, variant_path)


def venv_is_python_stale(pythonlibs):
    import shutil

    for variant, variant_path in venv_iterate_variants(pythonlibs):
        # Variant does not exist
        if not os.path.exists(variant_path):
            return True
        found = shutil.which(variant)
        # Asked for a variant that we don't have anymore... can't do much
        # This could happen if the user manually launches python from the
        # nix store without it on their PATH.
        if not found:
            continue
        # Variant points at a non-current Python
        if os.path.realpath(found) != os.path.realpath(variant_path):
            return True
    return False


def venv_should_patch(pythonlibs):
    import os

    # Don't patch if VIRTUAL_ENV doesn't match our .pythonlibs
    # If the user is managing their own venv, don't touch it.
    if os.environ.get("VIRTUAL_ENV") != pythonlibs:
        return False

    if not venv_is_python_stale(pythonlibs):
        return False

    return True


def venv_patch(pythonlibs):
    import os
    import sys

    real_executable = os.path.realpath(sys.executable)

    venv_setup_scaffolding(pythonlibs)
    venv_setup_pyvenv_cfg(pythonlibs, real_executable)
    venv_setup_python_links(pythonlibs, real_executable)


if __name__ == "sitecustomize":
    if pip_should_patch():
        pip_patch()

    import os

    pythonlibs = os.path.join(os.getenv("REPL_HOME", os.getcwd()), ".pythonlibs")
    if venv_should_patch(pythonlibs):
        venv_patch(pythonlibs)
