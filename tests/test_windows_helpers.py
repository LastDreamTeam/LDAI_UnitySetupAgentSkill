import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[1] / 'skills/ld-unitysetup-online/scripts'


@unittest.skipUnless(os.name == 'nt' and shutil.which('powershell'), 'Windows PowerShell required')
class WindowsHelpers(unittest.TestCase):
    def test_all_scripts_parse_in_available_powershell_hosts(self):
        """Parse every helper without execution in Windows PowerShell and available pwsh."""
        for host in ('powershell', 'pwsh'):
            if not shutil.which(host):
                continue
            for file in SCRIPTS.glob('*.ps1'):
                with self.subTest(host=host, script=file.name):
                    command = "$tokens=$null;$errors=$null;[void][System.Management.Automation.Language.Parser]::ParseFile($args[0],[ref]$tokens,[ref]$errors);if($errors.Count){$errors|ForEach-Object{$_.Message};exit 1}"
                    # Quote the literal path; parsing must never execute script operations.
                    quoted = str(file).replace("'", "''")
                    command = command.replace('$args[0]', "'" + quoted + "'")
                    result = subprocess.run([host, '-NoProfile', '-Command', command], capture_output=True, text=True)
                    self.assertEqual(0, result.returncode, file.name + ': ' + result.stdout + result.stderr)

    def _quote(self, value):
        """Encode a fixture path as a literal PowerShell single-quoted string."""
        return "'" + str(value).replace("'", "''") + "'"

    def _make_junction(self, link, target):
        """Create a directory junction entirely inside the temporary test fixture."""
        command = f"New-Item -ItemType Junction -Path {self._quote(link)} -Target {self._quote(target)} | Out-Null"
        result = subprocess.run(['powershell', '-NoProfile', '-Command', command], capture_output=True, text=True)
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)

    def _run_quarantine(self, root, *, apply=False):
        """Run the real quarantine workflow with only OS folders/process discovery isolated."""
        body = (SCRIPTS / 'Move-LDUnityChinaUserState.ps1').read_text(encoding='utf-8')
        # Replace only the known-folder boundary so no production AppData is reachable.
        for folder, name in (('ApplicationData', 'roaming'), ('LocalApplicationData', 'local')):
            expression = f"[Environment]::GetFolderPath('{folder}')"
            self.assertEqual(1, body.count(expression))
            body = body.replace(expression, self._quote(root / name))
        script = root / 'quarantine-fixture.ps1'
        script.write_text(body, encoding='utf-8')
        destination = root / 'local' / 'LDUnitySetup' / 'Quarantine' / 'test-run'
        # Process discovery is the only command replaced; no real app is closed or queried.
        command = ("function Get-Process { @() }; & " + self._quote(script)
                   + ' -UnityHubChinaCache -QuarantineRoot ' + self._quote(destination)
                   + (' -Apply' if apply else ''))
        return subprocess.run(['powershell', '-NoProfile', '-Command', command], capture_output=True, text=True)

    def test_quarantine_preview_and_apply_preserve_unselected_state(self):
        """Keep credentials/project lists while moving a reviewed cache with recovery metadata."""
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            hub = root / 'roaming' / 'UnityHub'
            hub.mkdir(parents=True)
            (root / 'local').mkdir()
            cache = hub / 'releases.json'
            cache.write_text('cache fixture')
            token = hub / 'encryptedTokens.json'
            token.write_text('synthetic protected fixture')
            projects = hub / 'projects-v1.json'
            projects.write_text('synthetic project list fixture')
            preview = self._run_quarantine(root)
            self.assertEqual(0, preview.returncode, preview.stdout + preview.stderr)
            self.assertTrue(cache.exists())
            result = self._run_quarantine(root, apply=True)
            self.assertEqual(0, result.returncode, result.stdout + result.stderr)
            self.assertFalse(cache.exists())
            self.assertEqual('synthetic protected fixture', token.read_text())
            self.assertEqual('synthetic project list fixture', projects.read_text())
            manifest_path = root / 'local' / 'LDUnitySetup' / 'Quarantine' / 'test-run' / 'manifest.json'
            manifest = json.loads(manifest_path.read_text(encoding='utf-8-sig'))
            self.assertEqual(1, len(manifest))
            self.assertEqual(cache, Path(manifest[0]['OriginalPath']))
            self.assertEqual('cache fixture', Path(manifest[0]['QuarantinedPath']).read_text())

    def test_quarantine_rejects_source_ancestor_junction(self):
        """Refuse a linked Hub parent before preview/apply can move an outside cache."""
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / 'roaming').mkdir()
            (root / 'local').mkdir()
            outside = root / 'outside'
            outside.mkdir()
            protected = outside / 'releases.json'
            protected.write_text('outside scope')
            self._make_junction(root / 'roaming' / 'UnityHub', outside)
            result = self._run_quarantine(root, apply=True)
            self.assertNotEqual(0, result.returncode)
            self.assertIn('Reparse point requires separate review', result.stderr)
            self.assertEqual('outside scope', protected.read_text())
            self.assertFalse((root / 'local' / 'LDUnitySetup').exists())

    def test_quarantine_rejects_destination_ancestor_junction(self):
        """Refuse a linked quarantine parent before moving any reviewed source file."""
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            hub = root / 'roaming' / 'UnityHub'
            hub.mkdir(parents=True)
            (root / 'local').mkdir()
            source = hub / 'releases.json'
            source.write_text('preserve cache')
            outside = root / 'outside'
            outside.mkdir()
            self._make_junction(root / 'local' / 'LDUnitySetup', outside)
            result = self._run_quarantine(root, apply=True)
            self.assertNotEqual(0, result.returncode)
            self.assertIn('Reparse point requires separate review', result.stderr)
            self.assertEqual('preserve cache', source.read_text())
            self.assertEqual([], list(outside.iterdir()))

    def test_nonempty_residual_directory_is_refused(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp) / 'Tuanjie Hub'
            directory.mkdir()
            protected = directory / 'user-project.txt'
            protected.write_text('preserve me')
            result = subprocess.run(['powershell', '-NoProfile', '-File', str(SCRIPTS / 'Remove-LDTuanjieProtocol.ps1'),
                                     '-ExpectedRemovedExecutable', str(directory / 'Tuanjie Hub.exe'),
                                     '-RemoveEmptyProgramDirectory'], capture_output=True, text=True)
            self.assertNotEqual(0, result.returncode)
            self.assertEqual('preserve me', protected.read_text())


if __name__ == '__main__':
    unittest.main()
