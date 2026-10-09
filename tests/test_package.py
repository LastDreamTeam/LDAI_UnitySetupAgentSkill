import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / 'skills/ld-unitysetup-online'


class PackageTests(unittest.TestCase):
    def test_all_local_markdown_targets_exist(self):
        for file in ROOT.rglob('*.md'):
            for raw in re.findall(r'\]\(([^)]+)\)', file.read_text(encoding='utf-8')):
                target = raw.strip('<>').split('#', 1)[0]
                if not target or '://' in target or target.startswith('mailto:'):
                    continue
                self.assertTrue((file.parent / target).exists(), f'{file.relative_to(ROOT)} -> {target}')

    def test_package_identity_and_resources(self):
        version = json.loads((SKILL / 'assets/version.json').read_text())
        self.assertEqual('ld-unitysetup-online', version['name'])
        self.assertEqual('LastDreamTeam/LDAI_UnitySetupAgentSkill', version['repository'])
        for item in ('SKILL.md', 'scripts/maintain.py', 'scripts/probe_routes.py',
                     'scripts/Test-LDUnitySetup.ps1', 'scripts/Get-LDUnityChinaInventory.ps1',
                     'references/proxy-routing.md', 'references/cleanup-lessons.md', 'agents/openai.yaml'):
            self.assertTrue((SKILL / item).is_file(), item)

    def test_no_workstation_credentials_or_paths(self):
        forbidden = [re.compile(r'(?i)afk_\w{12,}'), re.compile(r'(?i)gh[pousr]_\w{20,}'),
                     re.compile(r'(?i)[A-Z]:\\Users\\[A-Za-z0-9_.~-]+'),
                     re.compile(r'(?i)[A-Z]:\\app\\'), re.compile(r'(?i)"profileIndexId"\s*:')]
        for file in ROOT.rglob('*'):
            if not file.is_file() or '.git' in file.parts or file.suffix in ('.pyc', '.zip'):
                continue
            content = file.read_text(encoding='utf-8-sig')
            for pattern in forbidden:
                self.assertIsNone(pattern.search(content), f'Private material in {file.relative_to(ROOT)}')


if __name__ == '__main__':
    unittest.main()
