import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[1] / 'skills/ld-unitysetup-online/scripts'


@unittest.skipUnless(os.name == 'nt' and shutil.which('powershell'), 'Windows PowerShell required')
class WindowsHelpers(unittest.TestCase):
    def test_all_scripts_parse_in_windows_powershell(self):
        for file in SCRIPTS.glob('*.ps1'):
            command = "$tokens=$null;$errors=$null;[void][System.Management.Automation.Language.Parser]::ParseFile($args[0],[ref]$tokens,[ref]$errors);if($errors.Count){$errors|ForEach-Object{$_.Message};exit 1}"
            # Pass the literal path in a safely quoted PowerShell string, not a shell expression.
            quoted = str(file).replace("'", "''")
            command = command.replace('$args[0]', "'" + quoted + "'")
            result = subprocess.run(['powershell', '-NoProfile', '-Command', command], capture_output=True, text=True)
            self.assertEqual(0, result.returncode, file.name + ': ' + result.stdout + result.stderr)

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
