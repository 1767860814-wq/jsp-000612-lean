#!/usr/bin/env python3
"""Render public PR references locally. This program never posts or contacts GitHub."""
from __future__ import annotations
import argparse
import difflib
import hashlib
import json
import re
import subprocess
from pathlib import Path

PROOF_SHA256 = '587ea5a73de02a7b8916c7ab79baa1755c027c011551330553bfbba076aaa368'
TOKENS = ('PUBLIC_REPOSITORY_URL', 'PUBLIC_BRANCH', 'PUBLIC_COMMIT_SHA')
MARKER = '**Formalization submitted for review (JSP-000612; verification pending):**'


def validate_reference(repository: str, branch: str, commit: str) -> tuple[str, str, str]:
    repository = repository.strip().rstrip('/')
    if repository.endswith('.git'):
        repository = repository[:-4]
    if not re.fullmatch(r'https://github\.com/[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})/[A-Za-z0-9][A-Za-z0-9._-]{0,99}', repository):
        raise ValueError('Use an HTTPS GitHub owner/repository URL, without credentials, query, fragment or subpath.')
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._/-]{0,199}', branch):
        raise ValueError('Invalid branch characters; spaces and shell syntax are forbidden.')
    if ('..' in branch or '//' in branch or branch.endswith(('/', '.', '.lock'))
            or any(part.startswith('.') or part.endswith('.lock') for part in branch.split('/'))):
        raise ValueError('Invalid Git branch name.')
    if not re.fullmatch(r'[0-9a-fA-F]{40}', commit) or set(commit) == {'0'}:
        raise ValueError('Use the full nonzero 40-character Git commit, not a 64-character file SHA-256.')
    return repository, branch, commit.lower()


def render(text: str, repository: str, branch: str, commit: str) -> str:
    repository, branch, commit = validate_reference(repository, branch, commit)
    for old, new in zip(TOKENS, (repository, branch, commit)):
        text = text.replace(old, new)
    if any(token in text for token in TOKENS):
        raise ValueError('Unresolved reference placeholder.')
    return text


def patch_catalogue(text: str, insertion: str) -> str:
    """Insert evidence only inside the unique existing 612 entry; preserve its fields."""
    starts = list(re.finditer(r'^##\s+JSP-000612\b[^\n]*$', text, re.M))
    if len(starts) != 1:
        raise ValueError('Expected exactly one existing JSP-000612 section; do not create or guess a replacement entry.')
    start = starts[0].end()
    following = re.search(r'^##\s+', text[start:], re.M)
    end = start + following.start() if following else len(text)
    section = text[start:end]
    if MARKER in section:
        raise ValueError('This evidence marker already exists; update the existing submission instead of duplicating it.')
    return text[:end].rstrip() + '\n\n' + insertion.strip() + '\n\n' + text[end:]


def verify_local_commit(checkout: Path, commit: str) -> None:
    result = subprocess.run(['git', '-C', str(checkout), 'show', f'{commit}:JSP000612.lean'],
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30, check=False)
    if result.returncode:
        raise ValueError('Cannot read JSP000612.lean at that commit in the supplied local checkout.')
    if hashlib.sha256(result.stdout).hexdigest() != PROOF_SHA256:
        raise ValueError('The proof at the supplied local commit is not the verified source.')


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--repository', required=True)
    ap.add_argument('--branch', default='main')
    ap.add_argument('--commit', required=True)
    ap.add_argument('--output-dir', type=Path, default=Path('reproduction/submission'))
    ap.add_argument('--proof-checkout', type=Path)
    ap.add_argument('--catalogue', type=Path, help='Optional already-downloaded official catalogue; read-only input.')
    a = ap.parse_args()
    try:
        repository, branch, commit = validate_reference(a.repository, a.branch, a.commit)
        root = Path(__file__).resolve().parents[1]
        release_check = None
        if a.proof_checkout:
            from release_gate import verify_release
            release_check = verify_release(a.proof_checkout.resolve(), branch, commit,
                                           root/'MANIFEST_SHA256.json')
        out = a.output_dir.resolve()
        # Keep generated personal/public references out of the immutable delivery manifest.
        if out.is_relative_to(root) and not out.is_relative_to(root/'reproduction'):
            raise ValueError('Within this project, write generated references under reproduction/ only.')
        pr = render((root/'submission/PR_BODY_EN.template.md').read_text(), repository, branch, commit)
        insertion = render((root/'submission/CATALOG_INSERT_EN.template.md').read_text(), repository, branch, commit)
        patched = patch_catalogue(a.catalogue.read_text(), insertion) if a.catalogue else None
        out.mkdir(parents=True, exist_ok=True)
        (out/'PR_BODY_EN.md').write_text(pr)
        (out/'CATALOG_INSERT_EN.md').write_text(insertion)
        (out/'PR_TITLE.txt').write_text((root/'submission/PR_TITLE.txt').read_text())
        record = dict(repository=repository, branch=branch, commit=commit, proof_sha256=PROOF_SHA256,
                      local_commit_proof_checked=bool(release_check),
                      local_branch_and_full_release_checked=bool(release_check),
                      release_check=release_check, public_availability_checked=False,
                      posted=False, note='Reference syntax and optional full local release/ancestry check; NOT online/public verification.')
        (out/'PUBLIC_REFERENCE.json').write_text(json.dumps(record, indent=2)+'\n')
        if patched is not None:
            original = a.catalogue.read_text()
            (out/'catalog-0601-0700.md').write_text(patched)
            diff = difflib.unified_diff(original.splitlines(keepends=True), patched.splitlines(keepends=True),
                         fromfile='a/problems/catalog-0601-0700.md', tofile='b/problems/catalog-0601-0700.md')
            (out/'catalogue.patch').write_text(''.join(diff))
        print(f'RENDERED: {out}\nNOT POSTED; verify the public repository and commit before opening the PR.')
    except (ValueError, OSError, subprocess.SubprocessError) as exc:
        ap.error(str(exc))

if __name__ == '__main__':
    main()
