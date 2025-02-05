def pip_build_shebang(self, executable, post_interp):
    import os, sys
    if os.name != 'posix':
        simple_shebang = True
    else:
        # Add 3 for '#!' prefix and newline suffix.
        shebang_length = len(executable) + len(post_interp) + 3
        if sys.platform == 'darwin':
            max_shebang_length = 512
        else:
            max_shebang_length = 127
        simple_shebang = ((b' ' not in executable) and
                          (shebang_length <= max_shebang_length))

    if simple_shebang:
        result = b'#!/usr/bin/env python3' + post_interp + b'\n'
    else:
        result = b'#!/bin/sh\n'
        result += b"'''exec' python3" + post_interp + b' "$0" "$@"\n'
        result += b"' '''"
    return result

import sys
import os

repl_home = os.getenv('REPL_HOME')
if repl_home and sys.executable.startswith(repl_home + '/.pythonlibs/bin'):
    if 'PIP_CONFIG_FILE' in os.environ:
        os.environ.pop('PIP_CONFIG_FILE')

exe = sys.argv[0]
if exe.endswith('/pip') or exe.endswith('/pip3') or exe.endswith('/.pip-wrapped'):
    from pip._vendor.distlib.scripts import ScriptMaker
    ScriptMaker._build_shebang = pip_build_shebang

import os
pythonpath = os.getenv('REPLIT_PYTHONPATH')
if pythonpath:
  paths = pythonpath.split(':')
  sys.path.extend(paths)
