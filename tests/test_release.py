"""Run release scripts in temporary trees; no network or firmware builds."""

import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest
from html.parser import HTMLParser


REPO = Path(__file__).resolve().parents[1]
SHELL = shlex.split(os.environ.get("TEST_SHELL", "sh"))


class Fixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="build-release-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.work = self.root / "work"
        self.work.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}")
        self.env.pop("TARGET", None)
        self.env.update(
            GIT_AUTHOR_NAME="Release Test", GIT_AUTHOR_EMAIL="test@example.invalid",
            GIT_COMMITTER_NAME="Release Test", GIT_COMMITTER_EMAIL="test@example.invalid",
            GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull,
            GIT_TERMINAL_PROMPT="0",
        )
        for script in REPO.glob("*.sh"):
            shutil.copy(script, self.work / script.name)
        self.write("release.tag", "test-v1")
        self.feed = "feeds/x/rom/lede/"

    def write(self, name, text):
        path = self.work / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def executable(self, path, text):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("#!/bin/sh\n" + text)
        path.chmod(0o755)

    def mock(self, name, text):
        self.executable(self.bin / name, text)

    def run_script(self, name, *args, **env):
        return subprocess.run(
            [*SHELL, name, *args], cwd=self.work, env=dict(self.env, **env),
            text=True, capture_output=True, timeout=20,
        )

    def assertSuccess(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


class BuildTests(Fixture):
    def setUp(self):
        super().setUp()
        self.write(self.feed + "cfg.list", "myconfig.x86_64\nconfig.x86_64\nconfig.ax86_64\n")
        self.write(self.feed + "config.x86_64", "configuration\n")
        self.executable(self.work / self.feed / "make.sh",
                        'printf "%s|%s|%s\\n" "$CFGS" "$WORKFLOW" "$*" >builder.called\n')
        self.write("upload.sh", "echo upload >upload.called\n")
        self.mock("make", "echo diagnostic >diagnostic.called\nexit 9\n")
        self.mock("nproc", "echo 4\n")
        self.mock("sleep", ":\n")
        for name in ("df", "free"):
            self.mock(name, ":\n")

    def test_exact_configuration_and_default_jobs(self):
        # Standalone BusyBox ash may use its own nproc applet before PATH.
        cpus = subprocess.run([*SHELL, "-c", "nproc"], env=self.env,
                              text=True, capture_output=True, check=True).stdout.strip()
        self.assertSuccess(self.run_script("build.sh"))
        self.assertEqual((self.work / "builder.called").read_text(),
                         f"config.x86_64|1|make -j{cpus}\n")
        self.assertTrue((self.work / "upload.called").exists())

    def test_unknown_empty_and_pattern_targets_stop_before_build(self):
        for target in ("missing", "", "x86_6."):
            with self.subTest(target=target):
                self.assertNotEqual(self.run_script("build.sh", "2", TARGET=target).returncode, 0)
                self.assertFalse((self.work / "builder.called").exists())

    def test_missing_configuration_stops_before_build(self):
        (self.work / self.feed / "config.x86_64").unlink()
        self.assertNotEqual(self.run_script("build.sh", "2").returncode, 0)
        self.assertFalse((self.work / "builder.called").exists())

    def test_invalid_jobs_stop_before_build(self):
        for args in (("0",), ("-1",), ("bad",), ("2", "3")):
            with self.subTest(args=args):
                self.assertNotEqual(self.run_script("build.sh", *args).returncode, 0)
                self.assertFalse((self.work / "builder.called").exists())

    def test_build_failure_preserves_status_and_diagnostic_log(self):
        self.executable(self.work / self.feed / "make.sh", "exit 7\n")
        self.assertEqual(self.run_script("build.sh", "2").returncode, 7)
        self.assertTrue((self.work / "diagnostic.called").exists())
        self.assertTrue((self.root / "make.log").exists())
        self.assertFalse((self.work / "upload.called").exists())

    def test_upload_failure_does_not_rebuild(self):
        self.write("upload.sh", "exit 13\n")
        self.assertEqual(self.run_script("build.sh", "2").returncode, 13)
        self.assertFalse((self.work / "diagnostic.called").exists())

    def test_invalid_release_cannot_be_sourced(self):
        self.write("release.tag", 'v1$(touch injected)')
        self.assertNotEqual(self.run_script("build.sh", "2").returncode, 0)
        self.assertFalse((self.work / "builder.called").exists())
        self.assertFalse((self.work / "injected").exists())


class UploadTests(Fixture):
    def setUp(self):
        super().setUp()
        self.write(self.feed + "gen_map.sh", "exit 0\n")
        self.image = self.write("bin/targets/test/generic/image.bin", "firmware\n")
        self.write("map.list", "sha256sums: sha256sums.txt\nP&W: image.bin\nOther: image.bin\n")
        self.write("sha256sums.txt", "checksum\n")
        for name in ("sdk_map.list", "sdk_upload.list", "sdk_sha256sums.txt"):
            self.write(name, "")

    def test_map_failure_is_propagated(self):
        self.write(self.feed + "gen_map.sh", "exit 17\n")
        self.assertEqual(self.run_script("upload.sh").returncode, 17)
        self.assertFalse((self.work / "rom").exists())
        self.assertTrue(self.image.exists())

    def test_missing_firmware_stops_before_moving(self):
        self.write("map.list", "Board: image.bin missing.bin\n")
        self.assertNotEqual(self.run_script("upload.sh").returncode, 0)
        self.assertTrue(self.image.exists())
        self.assertFalse((self.work / "rom").exists())

    def test_duplicate_filename_stops_before_moving(self):
        self.write("bin/targets/other/generic/image.bin", "other firmware\n")
        self.assertNotEqual(self.run_script("upload.sh").returncode, 0)
        self.assertTrue(self.image.exists())
        self.assertFalse((self.work / "rom").exists())

    def test_missing_sdk_stops_before_moving(self):
        self.write("sdk_upload.list", "bin/targets/test/generic/missing-sdk.tar.xz\n")
        self.assertNotEqual(self.run_script("upload.sh").returncode, 0)
        self.assertTrue(self.image.exists())
        self.assertFalse((self.work / "rom").exists())

    def test_no_firmware_fails(self):
        self.write("map.list", "sha256sums: sha256sums.txt\n")
        self.assertNotEqual(self.run_script("upload.sh").returncode, 0)
        self.assertFalse((self.work / "rom").exists())

    def test_missing_metadata_stops_before_moving(self):
        (self.work / "sha256sums.txt").unlink()
        self.assertNotEqual(self.run_script("upload.sh").returncode, 0)
        self.assertTrue(self.image.exists())

    def test_firmware_without_sdk_or_optional_package(self):
        self.assertSuccess(self.run_script("upload.sh"))
        self.assertEqual((self.work / "rom/image.bin").read_text(), "firmware\n")
        self.assertFalse(self.image.exists())
        self.assertEqual(len((self.work / "upload.list").read_text().splitlines()), 1)
        self.assertIn("P&amp;W", (self.work / "rom/index.html").read_text())
        self.assertTrue((self.work / "rom/sdk/index.html").exists())

    def test_sdk_and_optional_package_are_packaged(self):
        sdk = self.write("bin/targets/test/generic/x-wrt-sdk-test.tar.xz", "sdk\n")
        self.write("sdk_map.list", sdk.name + "\n")
        self.write("sdk_upload.list", str(sdk.relative_to(self.work)))
        self.write("bin/targets/test/generic/packages/kmod-mtd-rw_test.ipk", "module\n")
        self.assertSuccess(self.run_script("upload.sh"))
        self.assertEqual((self.work / "rom/sdk" / sdk.name).read_text(), "sdk\n")
        self.assertEqual((self.work / "rom/kmod-mtd-rw_test.ipk").read_text(), "module\n")

    def test_optional_package_copy_failure_is_propagated(self):
        self.write("bin/targets/test/generic/packages/kmod-mtd-rw_test.ipk", "module\n")
        (self.work / "rom").mkdir()
        (self.work / "rom/kmod-mtd-rw_test.ipk").symlink_to("missing-directory/package.ipk")
        self.assertNotEqual(self.run_script("upload.sh").returncode, 0)
        self.assertTrue(self.image.exists())

    def test_index_failure_is_propagated(self):
        self.write("gen_index.sh", "exit 14\n")
        self.assertEqual(self.run_script("upload.sh").returncode, 14)


class TableParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.table_stack = []
        self.links = []

    def handle_starttag(self, tag, attrs):
        if tag in ("table", "tr", "td", "th"):
            self.table_stack.append(tag)
        if tag == "a":
            self.links.append(dict(attrs).get("href"))

    def handle_endtag(self, tag):
        if tag in ("table", "tr", "td", "th"):
            if not self.table_stack or self.table_stack.pop() != tag:
                raise AssertionError(f"Unbalanced table element: {tag}")


class IndexTests(Fixture):
    def test_escaped_names_valid_rows_and_unterminated_last_line(self):
        filename = 'image&"<test>.bin'
        self.write(filename, "firmware\n")
        for script, mapping in (("gen_index.sh", "map.list"),
                                ("gen_sdk_index.sh", "sdk_map.list")):
            with self.subTest(script=script):
                self.write(mapping, "P&W <script>alert(1)</script>: " + filename
                           if mapping == "map.list" else filename)
                self.assertSuccess(self.run_script(script))
                html = (self.work / "index.html").read_text()
                self.assertEqual((self.work / "index.html").stat().st_mode & 0o777, 0o644)
                parser = TableParser()
                parser.feed(html)
                self.assertEqual(parser.table_stack, [])
                self.assertIn(filename, parser.links)
                self.assertNotIn("<script>", html)
                if mapping == "map.list":
                    self.assertIn("P&amp;W &lt;script&gt;", html)

    def test_missing_inputs_preserve_existing_index_and_backup(self):
        for script, mapping in (("gen_index.sh", "map.list"),
                                ("gen_sdk_index.sh", "sdk_map.list")):
            for missing_map in (True, False):
                with self.subTest(script=script, missing_map=missing_map):
                    self.write("index.html", "existing index")
                    self.write("index.html.old", "existing backup")
                    if missing_map:
                        (self.work / mapping).unlink(missing_ok=True)
                    else:
                        self.write(mapping, "Board: missing.bin\n"
                                   if mapping == "map.list" else "missing.tar.xz\n")
                    self.assertNotEqual(self.run_script(script).returncode, 0)
                    self.assertEqual((self.work / "index.html").read_text(), "existing index")
                    self.assertEqual((self.work / "index.html.old").read_text(), "existing backup")
                    self.assertEqual(list(self.work.glob("index.html.??????")), [])

    def test_first_generation_and_backup_on_success(self):
        self.write("map.list", "Board: image.bin\n")
        self.write("image.bin", "firmware\n")
        result = self.run_script("gen_index.sh")
        self.assertSuccess(result)
        self.assertEqual(result.stderr, "")
        original = (self.work / "index.html").read_text()
        self.assertSuccess(self.run_script("gen_index.sh"))
        self.assertEqual((self.work / "index.html.old").read_text(), original)


class ReleaseTests(Fixture):
    def git(self, *args):
        result = subprocess.run(["git", *args], cwd=self.work, env=self.env,
                                text=True, capture_output=True, timeout=20)
        self.assertSuccess(result)
        return result.stdout.strip()

    def setUp(self):
        super().setUp()
        self.write(".github/workflows/main.yml", (REPO / ".github/workflows/main.yml").read_text())
        self.write("target.list", (REPO / "target.list").read_text())
        self.write("unrelated.txt", "original\n")
        self.git("init", "-q")
        self.git("symbolic-ref", "HEAD", "refs/heads/master")
        # These are only disposable fixture files.
        self.git("add", ".")
        self.git("commit", "-qm", "initial")
        remote = self.root / "origin.git"
        self.git("init", "-q", "--bare", str(remote))
        self.git("remote", "add", "origin", str(remote))
        self.mock("sleep", ":\n")

    def test_invalid_suffix_pattern_and_unknown_targets_do_not_commit(self):
        before = self.git("rev-parse", "HEAD")
        for target in ("generic", "x86.*", "missing", ""):
            with self.subTest(target=target):
                self.assertNotEqual(self.run_script("update-tags.sh", target).returncode, 0)
                self.assertEqual(self.git("rev-parse", "HEAD"), before)
                self.assertEqual(self.git("status", "--porcelain"), "")

    def test_release_commit_preserves_unrelated_index_and_worktree(self):
        self.write("unrelated.txt", "staged change\n")
        self.git("add", "unrelated.txt")
        self.write("unrelated.txt", "unstaged change\n")
        self.write("release.tag", "test-v2\n")
        self.assertSuccess(self.run_script("update-tags.sh", "ramips-mt7621"))
        changed = self.git("show", "--format=", "--name-only", "HEAD").splitlines()
        self.assertEqual(changed, [".github/workflows/main.yml", "release.tag"])
        self.assertEqual(self.git("diff", "--cached", "--name-only"), "unrelated.txt")
        self.assertEqual(self.git("show", ":unrelated.txt"), "staged change")
        self.assertEqual((self.work / "unrelated.txt").read_text(), "unstaged change\n")
        workflow = (self.work / ".github/workflows/main.yml").read_text()
        self.assertEqual(workflow.count("name: x-wrt-test-v2=ramips-mt7621"), 2)
        self.assertIn("TARGET=ramips-mt7621 sh build.sh", workflow)
        self.assertEqual(self.git("rev-parse", "HEAD"), self.git("rev-parse", "origin/master"))
        self.assertEqual(list((self.work / ".github/workflows").glob("main.yml.??????")), [])

    def test_identical_release_can_trigger_another_build(self):
        self.assertSuccess(self.run_script("update-tags.sh", "x86_64"))
        before = self.git("rev-parse", "HEAD")
        self.assertSuccess(self.run_script("update-tags.sh", "x86_64"))
        self.assertNotEqual(self.git("rev-parse", "HEAD"), before)

    def test_other_branch_does_not_commit_or_push_master(self):
        self.git("checkout", "-qb", "other")
        before = self.git("rev-parse", "HEAD")
        self.assertNotEqual(self.run_script("update-tags.sh", "x86_64").returncode, 0)
        self.assertEqual(self.git("rev-parse", "HEAD"), before)
        self.assertEqual(self.git("status", "--porcelain"), "")


if __name__ == "__main__":
    unittest.main()
