import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from register import WORKLOADS, read_lock


class RegistrationTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.paths = {}
        for name, repository in WORKLOADS.items():
            value = {
                "source": {
                    "repository": f"https://github.com/SystemConsultantGroup/{repository}.git",
                    "revision": "a" * 40,
                },
                "image": f"ghcr.io/systemconsultantgroup/alumni-platform-{name}@sha256:" + "b" * 64,
            }
            path = self.root / f"{name}.json"
            path.write_text(json.dumps(value))
            self.paths[name] = path

    def test_valid_locks(self):
        for name, path in self.paths.items():
            self.assertIn("source", read_lock(path, name))

    def test_rejects_mutable_image_and_wrong_repository(self):
        path = self.paths["be"]
        original = json.loads(path.read_text())
        for image in ["ghcr.io/systemconsultantgroup/alumni-platform-be:latest",
                      "ghcr.io/another/project@sha256:" + "b" * 64]:
            value = dict(original, image=image)
            path.write_text(json.dumps(value))
            with self.assertRaises(ValueError):
                read_lock(path, "be")

    def test_rejects_short_revision(self):
        path = self.paths["user"]
        value = json.loads(path.read_text())
        value["source"]["revision"] = "abcdef"
        path.write_text(json.dumps(value))
        with self.assertRaises(ValueError):
            read_lock(path, "user")

    def run_registration(self):
        directory = self.root / "onboarding" / "alumni"
        directory.mkdir(parents=True, exist_ok=True)
        for name in ["register.py", "meta.yaml"]:
            shutil.copyfile(Path(__file__).with_name(name), directory / name)
        command = [sys.executable, str(directory / "register.py")]
        for name, path in self.paths.items():
            command.extend([f"--{name}", str(path)])
        return subprocess.run(command, capture_output=True, text=True)

    def test_creates_locks_and_refuses_overwrite(self):
        self.assertEqual(self.run_registration().returncode, 0)
        target = self.root / "applications" / "alumni" / "instances" / "production.yaml"
        original = target.read_text()
        self.assertEqual(set(json.loads(original)), set(WORKLOADS))
        self.assertNotEqual(self.run_registration().returncode, 0)
        self.assertEqual(target.read_text(), original)

    def test_rejects_mismatched_frontend_commits_without_writing(self):
        path = self.paths["admin"]
        value = json.loads(path.read_text())
        value["source"]["revision"] = "c" * 40
        path.write_text(json.dumps(value))
        self.assertNotEqual(self.run_registration().returncode, 0)
        self.assertFalse((self.root / "applications" / "alumni").exists())


if __name__ == "__main__":
    unittest.main()
