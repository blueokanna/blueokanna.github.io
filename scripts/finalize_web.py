"""Finalize the release artifact after Flutter has generated its files."""
from pathlib import Path
import json
import os
import shutil
import subprocess

ROOT = Path(__file__).resolve().parent.parent

def finalize():
    output = ROOT / 'build/web'
    if not (output / 'index.html').is_file():
        raise RuntimeError('Build Flutter Web before finalizing')
    shutil.copyfile(ROOT / 'web/retire_service_worker.js', output / 'flutter_service_worker.js')
    shutil.copyfile(ROOT / 'content/friends.json', output / 'friends.json')
    shutil.copyfile(ROOT / 'CNAME', output / 'CNAME')
    revision = os.environ.get('GITHUB_SHA') or subprocess.check_output(
        ['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    (output / 'release.json').write_text(json.dumps({'revision': revision, 'channel': 'flutter-actions'}), encoding='utf-8')
    print('Finalized release: non-navigating worker retirement, blogroll snapshot and revision')

if __name__ == '__main__':
    finalize()
