import json
import unittest
from scripts.build_posts import parse_post


class PostCompilerTest(unittest.TestCase):
    def document(self, **changes):
        metadata = dict(id='test-post', language='zh-CN', title='标题', summary='摘要', category='工程')
        metadata.update(changes)
        return '---\n' + json.dumps(metadata) + '\n---\n\n## 正文\n\n```md\n## fenced heading\n```'

    def test_preserves_markdown(self):
        post = parse_post(self.document(), 'zh-CN', 'test-post')
        self.assertIn('```md\n## fenced heading\n```', post['sections'][0]['body'])
        self.assertEqual(post['title'], '标题')

    def test_rejects_mismatched_path_and_metadata(self):
        for field in [dict(id='../escape'), dict(language='unknown'), dict(title='')]:
            with self.assertRaises(ValueError):
                parse_post(self.document(**field), 'zh-CN', 'test-post')

    def test_rejects_yaml_code_and_excessive_body(self):
        for document in ['---\n!!python/object:danger\n---\ntext', self.document() + '字' * 50000]:
            with self.assertRaises(ValueError):
                parse_post(document, 'zh-CN', 'test-post')


if __name__ == '__main__':
    unittest.main()
