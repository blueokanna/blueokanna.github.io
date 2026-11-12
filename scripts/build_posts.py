"""Compile repository Markdown into the offline Flutter article catalog.

Front matter is one JSON object between YAML delimiters (JSON is a YAML
subset). No template evaluation, network calls, or YAML tags are supported.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LANGUAGES = {'zh-CN', 'zh-TW', 'en', 'ja', 'de', 'fr', 'es', 'ru', 'pt', 'it'}


def parse_post(text, language, slug):
    match = re.match(r'^---\r?\n([^\n]+)\r?\n---\r?\n', text)
    if not match:
        raise ValueError(f'{language}/{slug}: missing JSON front matter')
    data = json.loads(match[1])
    if not isinstance(data, dict):
        raise ValueError('Front matter must be an object')
    if language not in LANGUAGES or not re.fullmatch(r'[a-z][a-z0-9-]{1,63}', slug):
        raise ValueError('Invalid locale or article ID')
    if data.get('language') != language or data.get('id') != slug:
        raise ValueError('Path and front matter do not match')
    for field, limit in [('title', 160), ('summary', 600), ('category', 40)]:
        value = data.get(field)
        if not isinstance(value, str) or not value.strip() or len(value) > limit:
            raise ValueError(f'Invalid {field}')
    body = text[match.end():].strip()
    if not body or len(body.encode('utf-8')) > 131072:
        raise ValueError('Body must contain 1–131072 UTF-8 bytes')
    # Preserve fenced headings and nested Markdown blocks without splitting.
    return {key: data[key] for key in ['id', 'language', 'title', 'summary', 'category']} | {
        'sections': [{'heading': '正文' if language.startswith('zh') else 'Article', 'body': body}], 'sources': []}


def main():
    posts = []
    for path in sorted((ROOT / 'content/posts').glob('*/*.md')):
        posts.append(parse_post(path.read_text(encoding='utf-8'), path.parent.name, path.stem))
    output = ROOT / 'assets/posts.json'
    output.write_text(json.dumps(posts, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Compiled {len(posts)} Markdown articles')


if __name__ == '__main__':
    main()
