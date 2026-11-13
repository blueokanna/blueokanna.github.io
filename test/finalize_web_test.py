import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    'finalize_web', Path(__file__).resolve().parents[1] / 'scripts/finalize_web.py'
)
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class FinalizeWebTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.output = self.root / 'build/web'
        (self.output / 'assets/content').mkdir(parents=True)
        (self.root / 'web').mkdir()
        (self.root / 'content').mkdir()
        (self.output / 'index.html').write_text('<!doctype html>', encoding='utf-8')
        (self.root / 'web/retire_service_worker.js').write_text('// worker', encoding='utf-8')
        (self.root / 'CNAME').write_text('example.com', encoding='utf-8')

    def finalize(self):
        with patch.object(release, 'ROOT', self.root), patch.dict(
            release.os.environ, {'GITHUB_SHA': 'test-revision'}
        ):
            release.finalize()

    def test_deleted_blogroll_is_not_restored_or_published_from_an_old_build(self):
        for name in ['friends.json', 'assets/content/friends.json']:
            (self.output / name).write_text('["stale snapshot"]', encoding='utf-8')
        self.finalize()
        self.assertFalse((self.root / 'content/friends.json').exists())
        self.assertFalse((self.output / 'friends.json').exists())
        self.assertFalse((self.output / 'assets/content/friends.json').exists())
        self.assertEqual(
            json.loads((self.output / 'release.json').read_text(encoding='utf-8'))['revision'],
            'test-revision',
        )

    def test_explicitly_saved_blogroll_is_published_when_present(self):
        content = b'[]\n'
        (self.root / 'content/friends.json').write_bytes(content)
        self.finalize()
        self.assertEqual((self.output / 'friends.json').read_bytes(), content)


if __name__ == '__main__':
    unittest.main()
