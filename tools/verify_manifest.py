#!/usr/bin/env python3
"""Verify the delivered file manifest. Run before editing the package."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path

IGNORED_DIRS = {'.git', '.lake', 'build', 'reproduction', '__pycache__'}
MANIFEST = 'MANIFEST_SHA256.json'


def included(root: Path, p: Path) -> bool:
    return p.is_file() and not (set(p.relative_to(root).parts) & IGNORED_DIRS) and p.name != MANIFEST


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    report = json.loads((root/MANIFEST).read_text())
    files = report['files']
    seen = set()
    for item in files:
        rel = item['path']; path = root/rel
        if rel in seen or Path(rel).is_absolute() or '..' in Path(rel).parts:
            raise ValueError(f'Invalid or duplicated manifest path: {rel}')
        seen.add(rel)
        if path.is_symlink() or not path.is_file() or not path.resolve().is_relative_to(root.resolve()):
            raise ValueError(f'Missing, symbolic, or escaped file: {rel}')
        raw = path.read_bytes()
        if len(raw) != item['bytes'] or hashlib.sha256(raw).hexdigest() != item['sha256']:
            raise ValueError(f'File-integrity mismatch: {rel}')
    actual = {p.relative_to(root).as_posix() for p in root.rglob('*') if included(root, p)}
    if actual != seen:
        raise ValueError(f'Manifest set mismatch; unlisted={sorted(actual-seen)}, missing={sorted(seen-actual)}')
    print(f'MANIFEST: PASS ({len(files)} files)')

if __name__ == '__main__':
    main()
