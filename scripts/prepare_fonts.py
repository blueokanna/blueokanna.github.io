"""Build licensed font subsets from pinned Google Fonts sources.

Run after editing translations. Original fonts are cached outside the web bundle.
The cache is verified even on subsequent runs; downloaded data is never executed.
"""
from pathlib import Path
import hashlib
import json
import sys
import urllib.request

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / '.font-tools'))
from fontTools import subset
from fontTools.ttLib import TTFont


def main():
    cache = ROOT / '.font-cache'
    cache.mkdir(exist_ok=True)
    text = ''.join(p.read_text(encoding='utf-8') for p in (ROOT / 'assets').rglob('*.json'))
    text += ''.join(p.read_text(encoding='utf-8') for p in (ROOT / 'lib').rglob('*.dart'))
    text += ''.join(p.read_text(encoding='utf-8') for p in (ROOT / 'content').rglob('*.mmd'))
    # Include Latin/Cyrillic alphabets, numbers, punctuation and Japanese kana,
    # as well as all characters in the maintained site content.
    characters = set(map(ord, text)) | set(range(0x20, 0x530)) | set(range(0x2000, 0x2070)) | set(range(0x3000, 0x3100))
    sources = json.loads((ROOT / 'scripts/font-sources.json').read_text(encoding='utf-8'))
    for source in sources:
        path = cache / (source['family'] + '.ttf')
        if not path.exists():
            with urllib.request.urlopen(source['url'], timeout=60) as response:
                path.write_bytes(response.read())
        if hashlib.sha256(path.read_bytes()).hexdigest() != source['sha256']:
            raise RuntimeError(f"Font checksum mismatch: {path.name}")
        options = subset.Options()
        options.recalc_timestamp = False
        options.layout_features = ['*']
        font = TTFont(path, recalcTimestamp=False)
        worker = subset.Subsetter(options=options)
        worker.populate(unicodes=characters)
        worker.subset(font)
        output = ROOT / 'assets/fonts' / (source['family'] + '.ttf')
        font.save(output)
        font.close()
        print(f'{output.name}: {output.stat().st_size:,} bytes')


if __name__ == '__main__':
    main()
