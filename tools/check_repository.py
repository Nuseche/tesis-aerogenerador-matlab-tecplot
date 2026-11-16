"""Audit input integrity, source naming, Python syntax and local documentation links."""
from pathlib import Path
import ast
import hashlib
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIRS = [*sorted(ROOT.glob('+*')), *[ROOT / p for p in
    ('cases', 'tests', 'tools', 'studies', 'migration', 'postprocessing')]]


def main():
    errors = []
    verified = 0
    for manifest in ('data/MANIFEST.sha256', 'reference/MANIFEST.sha256'):
        for line in (ROOT / manifest).read_text().splitlines():
            if not line.strip():
                continue
            digest, name = line.split(maxsplit=1)
            path = ROOT / name
            if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
                errors.append(f'Checksum mismatch or missing input: {name}')
            verified += 1
    files = sorted(set([*ROOT.glob('*.m'), *[p for d in SOURCE_DIRS
        for p in d.rglob('*') if p.suffix in ('.m', '.py')]]))
    hashes = {}
    for p in files:
        label = str(p.relative_to(ROOT))
        content = p.read_text()
        if p.suffix == '.py':
            try:
                ast.parse(content, filename=label)
            except SyntaxError as exc:
                errors.append(f'{label}: {exc}')
        else:
            first = next((s.strip() for s in content.splitlines()
                          if s.strip() and not s.lstrip().startswith('%')), '')
            match = re.match(r'function\s+(?:\[[^\]]*\]\s*=\s*|\w+\s*=\s*)?(\w+)', first)
            if first.startswith('classdef'):
                match = re.match(r'classdef\s+(?:\([^)]*\)\s*)?(\w+)', first)
            if match and match[1] != p.stem:
                errors.append(f'Entry point {match[1]} differs from filename: {label}')
        digest = hashlib.sha256(p.read_bytes()).hexdigest()
        if digest in hashes:
            errors.append(f'Duplicate maintained source: {label} and {hashes[digest]}')
        hashes[digest] = label
    documents = [ROOT / 'README.md', *[p for d in ('docs', 'cases', 'data',
        'reference', 'studies', 'postprocessing') for p in (ROOT / d).rglob('*.md')]]
    for p in documents:
        for link in re.findall(r'\]\(([^)]+)\)', p.read_text()):
            if '://' in link or link.startswith('#'):
                continue
            target = link.split('#')[0].strip('<>')
            if not (p.parent / target).exists():
                errors.append(f'Broken local link in {p.relative_to(ROOT)}: {target}')
    print(json.dumps({'verified_input_hashes': verified, 'maintained_sources': len(files),
                      'documents_checked': len(documents), 'errors': errors}, indent=2))
    return bool(errors)


if __name__ == '__main__':
    sys.exit(main())
