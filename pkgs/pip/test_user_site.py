import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile


PIP, PIP_LIB, CONFIG, SITECUSTOMIZE = sys.argv[1:]
sys.argv = sys.argv[:1]


class UserSiteTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.userbase = self.home / ".pythonlibs"
        self.env = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith(("PIP_", "PYTHON", "REPLIT_PYTHON"))
        }
        self.env.update(
            HOME=str(self.home),
            REPL_HOME=str(self.home),
            PYTHONUSERBASE=str(self.userbase),
            PYTHONPATH=os.pathsep.join([SITECUSTOMIZE, PIP_LIB]),
            PIP_CONFIG_FILE=CONFIG,
        )
        self.empty = self.home / "empty.txt"
        self.empty.touch()
        self.wheel = self.home / "user_site_probe-0.0.1-py3-none-any.whl"
        info = "user_site_probe-0.0.1.dist-info"
        with zipfile.ZipFile(self.wheel, "w") as wheel:
            wheel.writestr("user_site_probe.py", 'value = "installed"\n')
            wheel.writestr(
                f"{info}/METADATA",
                "Metadata-Version: 2.1\nName: user-site-probe\nVersion: 0.0.1\n",
            )
            wheel.writestr(
                f"{info}/WHEEL",
                "Wheel-Version: 1.0\nRoot-Is-Purelib: true\nTag: py3-none-any\n",
            )
            wheel.writestr(f"{info}/RECORD", "")
        self.requirements = self.home / "requirements.txt"
        self.requirements.write_text(f"{self.wheel}\n")

    def run_command(self, args, *, env=None, success=True):
        result = subprocess.run(
            args,
            env=self.env if env is None else env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result.stdout

    def assert_import(self, python, base, env=None):
        self.run_command(
            [
                python,
                "-c",
                "import pathlib, user_site_probe; "
                "assert user_site_probe.value == 'installed'; "
                f"assert pathlib.Path(user_site_probe.__file__).is_relative_to({str(base)!r})",
            ],
            env=env,
        )

    def test_requirements_install_into_userbase(self):
        for requirements in (self.empty, self.requirements):
            self.run_command([PIP, "install", "--no-index", "-r", str(requirements)])
        self.assert_import(sys.executable, self.userbase)

    def test_explicitly_disabled_user_site(self):
        env = dict(self.env, PYTHONNOUSERSITE="1")
        output = self.run_command(
            [PIP, "install", "--no-index", "-r", str(self.empty)],
            env=env,
            success=False,
        )
        self.assertIn("User site-packages are disabled for this Python", output)
        output = self.run_command(
            [sys.executable, "-s", "-m", "pip", "install", "--no-index", "-r", str(self.empty)],
            success=False,
        )
        self.assertIn("User site-packages are disabled for this Python", output)

    def test_virtualenv(self):
        self.run_command(
            [sys.executable, "-m", "venv", "--without-pip", str(self.userbase)]
        )
        python = str(self.userbase / "bin" / "python")
        self.run_command(
            [python, "-m", "pip", "install", "--no-index", "-r", str(self.requirements)]
        )
        self.assert_import(python, self.userbase)
        output = self.run_command(
            [python, "-m", "pip", "install", "--user", "--no-index", "-r", str(self.empty)],
            success=False,
        )
        self.assertIn("User site-packages are not visible in this virtualenv", output)


unittest.main()
