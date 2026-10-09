import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'skills/ld-unitysetup-online/scripts/maintain.py'
spec = importlib.util.spec_from_file_location('maintain', SCRIPT)
maintain = importlib.util.module_from_spec(spec)
spec.loader.exec_module(maintain)


@unittest.skipUnless(shutil.which('git'), 'git required')
class MaintenanceTests(unittest.TestCase):
    def git(self, root, *args):
        call = subprocess.run(['git', '-C', str(root), *args], text=True, capture_output=True)
        if call.returncode:
            self.fail(call.stderr)
        return call.stdout.strip()

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.remote = self.root / 'remote.git'
        self.publisher = self.root / 'publisher'
        self.publisher.mkdir()
        self.git(self.publisher, 'init', '--initial-branch=main')
        self.git(self.publisher, 'init', '--bare', '--initial-branch=main', str(self.remote))
        self.publish_skill = self.publisher / 'skills' / maintain.NAME
        (self.publish_skill / 'assets').mkdir(parents=True)
        (self.publish_skill / 'SKILL.md').write_text('Fixture skill\n')
        (self.publisher / '.gitignore').write_text('*.local\n')
        self.write_version('0.1.0')
        self.commit('initial fixture')
        self.git(self.publisher, 'remote', 'add', 'origin', self.remote.as_posix())
        self.git(self.publisher, 'push', '-u', 'origin', 'main')
        self.clone = self.root / 'installation'
        self.git(self.publisher, 'clone', self.remote.as_posix(), str(self.clone))
        self.origin_patch = patch.object(maintain, 'ORIGIN', self.remote.as_posix())
        self.origin_patch.start()
        self.addCleanup(self.origin_patch.stop)
        self.app = maintain.Maintainer(self.clone / 'skills' / maintain.NAME, self.root / 'data')

    def write_version(self, v):
        value = {'name': maintain.NAME, 'repository': maintain.REPOSITORY, 'version': v}
        (self.publish_skill / 'assets/version.json').write_text(json.dumps(value))
        return value

    def commit(self, message):
        self.git(self.publisher, 'add', '-A')
        self.git(self.publisher, '-c', 'user.name=Skill Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-m', message)

    def release(self):
        value = self.write_version('0.2.0')
        self.commit('next fixture release')
        self.git(self.publisher, 'push', 'origin', 'main')
        return value

    def test_check_and_approval_do_not_mutate_content(self):
        remote = self.release()
        head = self.git(self.clone, 'rev-parse', 'HEAD')
        tracking = self.git(self.clone, 'rev-parse', 'origin/main')
        with patch.object(maintain, 'remote_manifest', return_value=remote):
            self.assertEqual('update_available', self.app.check(True)['status'])
            self.assertEqual('update_confirmation_required', self.app.sync(idle=True)['status'])
            self.assertEqual('deferred_until_idle', self.app.sync(approve=True)['status'])
        self.assertEqual(head, self.git(self.clone, 'rev-parse', 'HEAD'))
        self.assertEqual(tracking, self.git(self.clone, 'rev-parse', 'origin/main'))

    def test_fast_forward_preserves_preferences_and_snapshot(self):
        remote = self.release()
        config = self.app.config()
        config['interval_days'] = 14
        maintain.write_json(self.app.config_file, config)
        with patch.object(maintain, 'remote_manifest', return_value=remote):
            result = self.app.sync(idle=True, approve=True, force=True)
        self.assertEqual('updated', result['status'])
        self.assertTrue(Path(result['snapshot']).is_file())
        self.assertEqual(14, self.app.config()['interval_days'])
        self.assertFalse(self.app.config()['auto_update'])

    def test_dirty_worktree_stops_without_overwrite(self):
        remote = self.release()
        user_file = self.clone / 'skills' / maintain.NAME / 'SKILL.md'
        user_file.write_text('Local user edit\n')
        with patch.object(maintain, 'remote_manifest', return_value=remote):
            with self.assertRaisesRegex(RuntimeError, 'Local modifications'):
                self.app.sync(idle=True, approve=True, force=True)
        self.assertEqual('Local user edit\n', user_file.read_text())

    def test_corrupt_config_and_concurrent_lock_are_preserved(self):
        self.app.config_file.write_text('{broken')
        with self.assertRaises(json.JSONDecodeError):
            self.app.config()
        self.assertEqual('{broken', self.app.config_file.read_text())
        with self.app.lock():
            with self.assertRaises(FileExistsError):
                with self.app.lock():
                    self.fail('second owner entered')
            self.assertTrue((self.app.data / 'maintenance.lock').exists())
        self.assertFalse((self.app.data / 'maintenance.lock').exists())

    def test_network_failure_does_not_record_success(self):
        with patch.object(maintain, 'remote_manifest', side_effect=OSError('fixture network failure')):
            with self.assertRaises(RuntimeError):
                self.app.check(True)
        state = maintain.read_json(self.app.state_file)
        self.assertIn('last_attempt', state)
        self.assertNotIn('last_success', state)
        self.assertEqual('official_version_check_failed', state['last_error'])


if __name__ == '__main__':
    unittest.main()
