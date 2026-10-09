import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / 'skills/ld-unitysetup-online'


class DownloadKnowledgeTests(unittest.TestCase):
    def test_fallback_guide_is_wired_into_actual_workflow(self):
        guide = SKILL / 'references/download-fallbacks.md'
        self.assertTrue(guide.is_file(), 'NoUnityCN needs an actionable fallback guide')
        for rel in ('SKILL.md', 'references/install-and-repair.md', 'references/sources.md'):
            self.assertIn('download-fallbacks.md', (SKILL / rel).read_text(encoding='utf-8'))
        text = guide.read_text(encoding='utf-8')
        for item in ('nounitycn-vinext.danke666.top', 'nounitycn.danke666.top',
                     'services.api.unity.com/unity/editor/release/v1/releases',
                     'unityhub://', 'checksums.md5', 'USE_CLIENT_SIDE_FETCH',
                     '离线', '签名', '授权'):
            self.assertIn(item, text)

    def test_community_references_keep_lower_priority_and_unknown_status(self):
        p = SKILL / 'references/community-reference-notes.md'
        self.assertTrue(p.is_file(), 'Historical articles require separate status and precedence')
        text = p.read_text(encoding='utf-8')
        for item in ('原技能已验证实践优先', '19614230', '1914827912286307473',
                     '可能过期', '曾成功过一次', '403', '未读取正文', 'f1'):
            self.assertIn(item, text)
        self.assertIn('community-reference-notes.md', (SKILL / 'SKILL.md').read_text(encoding='utf-8'))
        self.assertIn('community-reference-notes.md', (SKILL / 'references/sources.md').read_text(encoding='utf-8'))

    def test_skill_and_manifest_versions_match(self):
        text = (SKILL / 'SKILL.md').read_text(encoding='utf-8')
        match = re.search(r'^\s+version: "([0-9.]+)"$', text, re.M)
        self.assertIsNotNone(match)
        assert match is not None
        version = json.loads((SKILL / 'assets/version.json').read_text(encoding='utf-8'))
        self.assertEqual(match.group(1), version['version'])


if __name__ == '__main__':
    unittest.main()
