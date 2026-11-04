"""Behavioral regression checks for the vendored mise installer."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


class MiseBootstrapTests(unittest.TestCase):
    def test_install_path_directory_is_preserved(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            install_path = Path(temp_dir) / "existing-directory"
            install_path.mkdir()
            sentinel = install_path / "sentinel"
            sentinel.touch()
            env = os.environ.copy()
            env.update(HOME=temp_dir, MISE_INSTALL_PATH=str(install_path), MISE_INSTALL_HELP="0")
            result = subprocess.run(
                ["sh", str(ROOT / "scripts/install-mise.sh")],
                env=env, text=True, capture_output=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("mise install path is a directory", result.stderr)
            self.assertTrue(install_path.is_dir())
            self.assertTrue(sentinel.exists())


if __name__ == "__main__":
    unittest.main()
