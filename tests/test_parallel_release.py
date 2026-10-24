"""Run release scripts in temporary trees; no network or firmware builds."""

import hashlib
import os
import re
import tarfile
import zipfile
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



class GeneratorFixture(Fixture):
    def setUp(self):
        super().setUp()
        for name in ('release-header.yml', 'release-main.yml', 'release-upload-one.yml'):
            shutil.copy(REPO / name, self.work / name)
        self.write('.github/workflows/release.yml', 'original workflow\n')
        self.write('target.list', 'BTARGET=first second\nBTARGET=third\n')
        self.config_dir = self.root / 'configs'
        self.config_dir.mkdir()
        self.env['RELEASE_CONFIG_DIR'] = str(self.config_dir)
        for target, device in (('first', 'one'), ('second', 'two'), ('third', 'three')):
            (self.config_dir / ('config.' + target)).write_text(
                f'CONFIG_TARGET_DEVICE_{target}_generic_DEVICE_{device}=y\n'
                f'CONFIG_TARGET_DEVICE_PACKAGES_{target}_generic_DEVICE_{device}="extra"\n')

    def generate(self, *args):
        return self.run_script('update-tags.sh', '--generate-only', *args)

    def workflow(self):
        return (self.work / '.github/workflows/release.yml').read_text()


class GeneratorTests(GeneratorFixture):
    def test_grouped_targets_use_each_configuration(self):
        self.assertSuccess(self.generate())
        text = self.workflow()
        self.assertIn('build-first_second:', text)
        self.assertIn('BTARGET="first second"', text)
        self.assertEqual(re.findall(r'asset_name: (.*)', text), [
            'x-wrt-first-apps.zip', 'x-wrt-first-one.zip',
            'x-wrt-second-apps.zip', 'x-wrt-second-two.zip',
            'x-wrt-third-apps.zip', 'x-wrt-third-three.zip'])
        ids = re.findall(r'id: asset-(.*)', text)
        self.assertEqual(len(ids), len(set(ids)))
        self.assertSuccess(self.generate())
        self.assertEqual(self.workflow(), text)

    def test_exact_selector_selects_whole_group(self):
        self.assertSuccess(self.generate('second'))
        self.assertIn('x-wrt-first-one.zip', self.workflow())
        self.assertIn('x-wrt-second-two.zip', self.workflow())
        self.assertNotIn('build-third:', self.workflow())

    def test_invalid_suffix_pattern_and_unknown_selector_preserve_workflow(self):
        for selector in ('cond', 'sec.*', 'missing'):
            with self.subTest(selector=selector):
                self.assertNotEqual(self.generate(selector).returncode, 0)
                self.assertEqual(self.workflow(), 'original workflow\n')
                self.assertEqual(list((self.work / '.github/workflows').glob('release.yml.*')), [])

    def test_missing_configuration_preserves_workflow(self):
        (self.config_dir / 'config.second').unlink()
        self.assertNotEqual(self.generate().returncode, 0)
        self.assertEqual(self.workflow(), 'original workflow\n')
        self.assertEqual(list((self.work / '.github/workflows').glob('release.yml.*')), [])

    def test_empty_configuration_preserves_workflow(self):
        (self.config_dir / 'config.second').write_text('')
        self.assertNotEqual(self.generate().returncode, 0)
        self.assertEqual(self.workflow(), 'original workflow\n')

    def test_last_target_without_newline(self):
        self.write('target.list', 'BTARGET=third')
        self.assertSuccess(self.generate())
        self.assertIn('x-wrt-third-three.zip', self.workflow())


class PublishTests(GeneratorFixture):
    def git(self, *args):
        result = subprocess.run(['git', *args], cwd=self.work, env=self.env,
                                text=True, capture_output=True, timeout=20)
        self.assertSuccess(result)
        return result.stdout.strip()

    def setUp(self):
        super().setUp()
        self.write('unrelated.txt', 'original\n')
        self.git('init', '-q')
        self.git('symbolic-ref', 'HEAD', 'refs/heads/parallel-jobs')
        self.git('add', '.')  # Only temporary fixture files.
        self.git('commit', '-qm', 'initial')
        self.remote = self.root / 'origin.git'
        self.git('init', '-q', '--bare', str(self.remote))
        self.git('remote', 'add', 'origin', str(self.remote))

    def test_release_pushes_branch_and_tag_without_unrelated_changes(self):
        self.write('unrelated.txt', 'staged\n')
        self.git('add', 'unrelated.txt')
        self.write('unrelated.txt', 'unstaged\n')
        self.write('release.tag', 'test-v2\n')
        self.assertSuccess(self.run_script('update-tags.sh'))
        self.assertEqual(self.git('show', '--format=', '--name-only', 'HEAD').splitlines(),
                         ['.github/workflows/release.yml', 'release.tag'])
        self.assertEqual(self.git('diff', '--cached', '--name-only'), 'unrelated.txt')
        self.assertEqual(self.git('show', ':unrelated.txt'), 'staged')
        self.assertEqual((self.work / 'unrelated.txt').read_text(), 'unstaged\n')
        head = self.git('rev-parse', 'HEAD')
        self.assertEqual(self.git('--git-dir', str(self.remote), 'rev-parse',
                                  'refs/heads/parallel-jobs'), head)
        self.assertEqual(self.git('--git-dir', str(self.remote), 'rev-parse',
                                  'refs/tags/vtest-v2'), head)

    def test_existing_tag_stops_before_commit_or_workflow_change(self):
        self.git('tag', 'vtest-v1')
        before = self.git('rev-parse', 'HEAD')
        self.assertNotEqual(self.run_script('update-tags.sh').returncode, 0)
        self.assertEqual(self.git('rev-parse', 'HEAD'), before)
        self.assertEqual(self.workflow(), 'original workflow\n')

    def test_other_branch_stops_before_commit(self):
        self.git('checkout', '-qb', 'other')
        before = self.git('rev-parse', 'HEAD')
        self.assertNotEqual(self.run_script('update-tags.sh').returncode, 0)
        self.assertEqual(self.git('rev-parse', 'HEAD'), before)
        self.assertEqual(self.workflow(), 'original workflow\n')

    def test_rejected_branch_does_not_publish_tag(self):
        self.git('push', '-q', 'origin', 'HEAD:refs/heads/parallel-jobs')
        before = self.git('rev-parse', 'HEAD')
        hook = self.remote / 'hooks/update'
        self.executable(hook, 'case "$1" in refs/heads/parallel-jobs) exit 1 ;; esac\n')
        self.assertNotEqual(self.run_script('update-tags.sh').returncode, 0)
        self.assertEqual(self.git('--git-dir', str(self.remote), 'rev-parse',
                                  'refs/heads/parallel-jobs'), before)
        self.assertEqual(self.git('--git-dir', str(self.remote), 'tag', '--list'), '')


class BuildTests(Fixture):
    def setUp(self):
        super().setUp()
        self.write(self.feed + 'cfg.list', 'myconfig.first\nconfig.first\nconfig.second\n')
        for target in ('first', 'second', 'unrelated'):
            self.write(self.feed + 'config.' + target,
                       'CONFIG_SDK=y\nCONFIG_SDK_LLVM_BPF=y\n')
        self.executable(self.work / self.feed / 'make.sh',
                        'printf "%s|%s|%s|%s\\n" "$CFGS" "$WORKFLOW" "$TMPFS" "$*" >builder.called\n')
        self.write('upload.sh', 'echo upload >upload.called\n')
        self.write('pigz/pigz', 'placeholder\n')
        with tarfile.open(self.work / 'pigz.tar.gz', 'w:gz') as archive:
            archive.add(self.work / 'pigz', arcname='pigz')
        self.env['TEST_WORK'] = str(self.work)
        self.env['BTARGET'] = 'first'
        self.mock('make', 'if [ "$PWD" = "$TEST_WORK/pigz" ]; then exit "${PIGZ_STATUS:-0}"; fi\n'
                         'echo diagnostic >diagnostic.called\nexit 9\n')
        self.mock('sudo', 'exit 0\n')
        self.mock('git', 'exit 0\n')
        self.mock('nproc', 'echo 4\n')
        for name in ('df', 'free', 'sleep'):
            self.mock(name, ':\n')

    def test_grouped_build_deduplicates_configs_and_only_disables_selected_sdk(self):
        self.assertSuccess(self.run_script('build.sh', '3', BTARGET='first second first'))
        self.assertEqual((self.work / 'builder.called').read_text(),
                         'config.first config.second|0|1|make -j3\n')
        for target in ('first', 'second'):
            text = (self.work / self.feed / ('config.' + target)).read_text()
            self.assertEqual(text, '# CONFIG_SDK is not set\nCONFIG_SDK_LLVM_BPF=y\n')
        self.assertIn('CONFIG_SDK=y', (self.work / self.feed / 'config.unrelated').read_text())

    def test_invalid_empty_or_partly_unknown_group_stops_before_build(self):
        for target in ('', 'missing', 'first missing', 'fir.*'):
            with self.subTest(target=target):
                self.assertNotEqual(self.run_script('build.sh', '2', BTARGET=target).returncode, 0)
                self.assertFalse((self.work / 'builder.called').exists())
                self.assertFalse((self.work / '.build_x').exists())

    def test_default_jobs_are_bounded(self):
        cpus = subprocess.run([*SHELL, '-c', 'nproc'], env=self.env,
                              text=True, capture_output=True, check=True).stdout.strip()
        self.assertSuccess(self.run_script('build.sh'))
        self.assertIn('|make -j' + cpus, (self.work / 'builder.called').read_text())

    def test_invalid_job_counts_stop_before_build(self):
        for jobs in ('0', '-1', 'bad'):
            self.assertNotEqual(self.run_script('build.sh', jobs).returncode, 0)
            self.assertFalse((self.work / 'builder.called').exists())

    def test_pigz_failure_stops_before_firmware_build(self):
        self.assertEqual(self.run_script('build.sh', '2', PIGZ_STATUS='7').returncode, 7)
        self.assertFalse((self.work / 'builder.called').exists())

    def test_build_failure_preserves_status_and_log(self):
        self.executable(self.work / self.feed / 'make.sh', 'exit 17\n')
        self.assertEqual(self.run_script('build.sh', '2').returncode, 17)
        self.assertTrue((self.work / 'make.log').exists())
        self.assertTrue((self.work / 'diagnostic.called').exists())
        self.assertFalse((self.work / 'upload.called').exists())

    def test_upload_failure_does_not_run_diagnostic_build(self):
        self.write('upload.sh', 'exit 13\n')
        self.assertEqual(self.run_script('build.sh', '2').returncode, 13)
        self.assertFalse((self.work / 'diagnostic.called').exists())


class UploadTests(Fixture):
    def setUp(self):
        super().setUp()
        self.write(self.feed + 'gen_map.sh', 'exit 0\n')
        self.write('.build_x/env', 'CONFIG_VERSION_NUMBER="test"\n')
        self.env['CFGS'] = 'config.first'
        self.configure('first', 'first', 'arch_one', ('board',))
        self.paths = []
        self.add_image('first', 'board')
        self.write('rom/unrelated.txt', 'keep\n')

    def configure(self, cfg, board, arch, devices):
        self.write('.build_x/config.' + cfg,
                   f'CONFIG_TARGET_BOARD="{board}"\nCONFIG_TARGET_SUBTARGET="generic"\n'
                   f'CONFIG_TARGET_ARCH_PACKAGES="{arch}"\n' + ''.join(
                       f'CONFIG_TARGET_DEVICE_{board}_generic_DEVICE_{device}=y\n'
                       for device in devices))
        (self.work / 'bin/targets' / board / 'generic').mkdir(parents=True, exist_ok=True)

    def add_image(self, board, device):
        name = f'x-wrt-test-{board}-generic-{device}-sysupgrade.bin'
        path = self.write(f'bin/targets/{board}/generic/{name}', board + ':' + device)
        self.paths.append(path)
        self.manifests()
        return path

    def manifests(self):
        self.write('upload.list', '\n'.join(str(path.relative_to(self.work)) for path in self.paths))
        self.write('map.list', ''.join(f'P&W: {path.name}\n' for path in self.paths))
        self.write('sha256sums.txt', ''.join(
            hashlib.sha256(path.read_bytes()).hexdigest() + '  ' + path.name + '\n'
            for path in self.paths))

    def check_archive(self, name, expected):
        with zipfile.ZipFile(self.work / name) as archive:
            files = {path for path in archive.namelist() if not path.endswith('/')}
            self.assertEqual(files, set(expected))
            return {path: archive.read(path) for path in files}

    def test_device_archive_contents_checksums_and_original_files(self):
        self.assertSuccess(self.run_script('upload.sh'))
        image = self.paths[0]
        data = self.check_archive('x-wrt-first-board.zip', [
            'rom/' + image.name, 'rom/map.list', 'rom/sha256sums.txt', 'rom/index.html'])
        self.assertEqual(data['rom/' + image.name], image.read_bytes())
        self.assertIn(b'P&amp;W', data['rom/index.html'])
        self.assertIn(image.name.encode(), data['rom/sha256sums.txt'])
        self.assertTrue(image.exists())
        self.assertEqual((self.work / 'rom/unrelated.txt').read_text(), 'keep\n')
        self.assertEqual(list(self.work.glob('.release-pack.*')), [])

    def test_device_prefix_overlap_does_not_mix_firmware(self):
        self.configure('first', 'first', 'arch_one', ('board', 'board-pro'))
        pro = self.add_image('first', 'board-pro')
        self.assertSuccess(self.run_script('upload.sh'))
        for device, image in (('board', self.paths[0]), ('board-pro', pro)):
            with zipfile.ZipFile(self.work / f'x-wrt-first-{device}.zip') as archive:
                binaries = [path for path in archive.namelist() if path.endswith('.bin')]
                self.assertEqual(binaries, ['rom/' + image.name])

    def test_multi_target_apps_and_firmware_use_matching_architecture(self):
        self.configure('second', 'second', 'arch_two', ('other',))
        self.add_image('second', 'other')
        self.env['CFGS'] = 'config.first config.second'
        for board, arch in (('first', 'arch_one'), ('second', 'arch_two')):
            self.write(f'bin/packages/{arch}/packages/zerotier_1.ipk', board)
            self.write(f'bin/targets/{board}/generic/packages/kmod-mtd-rw_1.ipk', board)
        self.assertSuccess(self.run_script('upload.sh'))
        for board in ('first', 'second'):
            data = self.check_archive(f'x-wrt-{board}-apps.zip',
                                      ['rom/zerotier_1.ipk', 'rom/kmod-mtd-rw_1.ipk'])
            self.assertEqual(set(data.values()), {board.encode()})
        self.assertTrue((self.work / 'x-wrt-second-other.zip').exists())

    def test_map_failure_stops_before_cleanup(self):
        self.write(self.feed + 'gen_map.sh', 'exit 17\n')
        self.write('build_dir/target-test/keep', 'keep')
        self.assertEqual(self.run_script('upload.sh').returncode, 17)
        self.assertTrue((self.work / 'build_dir/target-test/keep').exists())
        self.assertEqual(list(self.work.glob('*.zip')), [])

    def test_missing_firmware_does_not_create_device_archive(self):
        self.paths[0].unlink()
        self.assertNotEqual(self.run_script('upload.sh').returncode, 0)
        self.assertFalse((self.work / 'x-wrt-first-board.zip').exists())

    def test_checksum_mismatch_fails(self):
        self.paths[0].write_text('corrupt')
        self.assertNotEqual(self.run_script('upload.sh').returncode, 0)
        self.assertFalse((self.work / 'x-wrt-first-board.zip').exists())

    def test_missing_checksum_fails(self):
        self.write('sha256sums.txt', 'unrelated checksum\n')
        self.assertNotEqual(self.run_script('upload.sh').returncode, 0)
        self.assertFalse((self.work / 'x-wrt-first-board.zip').exists())

    def test_incomplete_map_fails(self):
        self.write('map.list', 'Board: missing.bin\n')
        self.assertNotEqual(self.run_script('upload.sh').returncode, 0)
        self.assertFalse((self.work / 'x-wrt-first-board.zip').exists())

    def test_device_zip_failure_is_propagated(self):
        self.executable(self.bin / 'zip', 'case "$PWD" in *release-pack*) '
                        'if [ -f rom/index.html ]; then exit 23; fi ;; esac\n'
                        'exec /usr/bin/zip "$@"\n')
        self.assertEqual(self.run_script('upload.sh').returncode, 23)
        self.assertTrue(self.paths[0].exists())
        self.assertEqual(list(self.work.glob('.release-pack.*')), [])

    def test_index_failure_is_propagated_and_existing_zip_preserved(self):
        self.write('gen_index.sh', 'exit 19\n')
        self.write('x-wrt-first-board.zip', 'old archive')
        self.assertEqual(self.run_script('upload.sh').returncode, 19)
        self.assertEqual((self.work / 'x-wrt-first-board.zip').read_text(), 'old archive')

    def test_unclaimed_firmware_fails(self):
        self.add_image('first', 'unknown')
        self.assertNotEqual(self.run_script('upload.sh').returncode, 0)

    def test_stale_zip_entries_are_removed_on_success(self):
        with zipfile.ZipFile(self.work / 'x-wrt-first-board.zip', 'w') as archive:
            archive.writestr('rom/stale.bin', 'stale')
        self.assertSuccess(self.run_script('upload.sh'))
        with zipfile.ZipFile(self.work / 'x-wrt-first-board.zip') as archive:
            self.assertNotIn('rom/stale.bin', archive.namelist())


if __name__ == '__main__':
    unittest.main()
