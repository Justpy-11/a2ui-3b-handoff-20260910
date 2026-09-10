#!/usr/bin/env python3
import argparse
import hashlib
import json
from pathlib import Path

def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as source:
        for block in iter(lambda: source.read(16 * 1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()

parser = argparse.ArgumentParser(description='Verify Release assets and reassemble 03-完整工程项目.zip')
parser.add_argument('--asset-dir', required=True, type=Path)
parser.add_argument('--output', required=True, type=Path)
parser.add_argument('--manifest', type=Path, default=Path(__file__).resolve().parent.parent / 'release-manifest.json')
args = parser.parse_args()
if args.output.exists():
    raise SystemExit(f'Refusing to overwrite: {args.output}')
manifest = json.loads(args.manifest.read_text(encoding='utf-8'))
all_assets = [*manifest.get('releaseAssets', []), *manifest.get('deferredAssets', [])]
parts = sorted((x for x in all_assets if x.get('original') == '03-完整工程项目.zip' and 'part' in x), key=lambda x: x['part'])
expected = next(x for x in manifest['originalArchives'] if x['name'] == '03-完整工程项目.zip')
args.output.parent.mkdir(parents=True, exist_ok=True)
try:
    with args.output.open('xb') as target:
        for item in parts:
            source = args.asset_dir / item['name']
            if source.stat().st_size != item['bytes'] or digest(source) != item['sha256']:
                raise ValueError(f'Part verification failed: {item["name"]}')
            with source.open('rb') as stream:
                for block in iter(lambda: stream.read(16 * 1024 * 1024), b''):
                    target.write(block)
    if args.output.stat().st_size != expected['bytes'] or digest(args.output) != expected['sha256']:
        raise ValueError('Reassembled archive verification failed')
except Exception:
    args.output.unlink(missing_ok=True)
    raise
print(f'PASS: {args.output}')
print(f'SHA256: {expected["sha256"]}')
