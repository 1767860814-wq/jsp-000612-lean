#!/usr/bin/env python3
"""Read-only check of a pinned Git release against the trusted delivered manifest.

This checks local Git objects and branch ancestry, NOT remote availability,
public priority, the mathematical theorem, or official prize eligibility.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess


class ReleaseCheckError(ValueError):
    pass


def git(checkout: Path, *args: str) -> bytes:
    env = dict(os.environ, GIT_TERMINAL_PROMPT='0', GIT_CONFIG_NOSYSTEM='1',
               GIT_NO_REPLACE_OBJECTS='1', GIT_PAGER='cat')
    p = subprocess.run(['git', '-C', str(checkout), *args], stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE, timeout=30, check=False, env=env)
    if p.returncode:
        raise ReleaseCheckError(f'Git operation failed ({args[0]}): '
                                + p.stderr.decode('utf-8', errors='replace')[:600])
    return p.stdout


def verify_release(checkout: Path, branch: str, commit: str, trusted_manifest: Path) -> dict:
    checkout = checkout.resolve(strict=True)
    trusted_manifest = trusted_manifest.resolve(strict=True)
    if not re.fullmatch(r'[0-9a-fA-F]{40}', commit) or set(commit) == {'0'}:
        raise ReleaseCheckError('Commit must be a full nonzero 40-character Git SHA.')
    commit = commit.lower()
    # Check actual branch syntax without letting an argument become an option.
    if not branch or branch.startswith('-'):
        raise ReleaseCheckError('Invalid branch name.')
    git(checkout, 'check-ref-format', 'refs/heads/' + branch)
    if git(checkout, 'cat-file', '-t', commit).strip() != b'commit':
        raise ReleaseCheckError('The supplied object is not a commit.')
    # Prefer the exact local branch; a missing local branch may use origin's tracking ref.
    ref = None
    for candidate in ('refs/heads/' + branch, 'refs/remotes/origin/' + branch):
        try:
            tip = git(checkout, 'show-ref', '--verify', '--hash', candidate).decode().strip()
        except ReleaseCheckError:
            continue
        ref = candidate
        break
    if ref is None:
        raise ReleaseCheckError('The specified branch is not available in this local checkout.')
    try:
        git(checkout, 'merge-base', '--is-ancestor', commit, tip)
    except ReleaseCheckError as exc:
        raise ReleaseCheckError('The selected branch does not contain the pinned commit.') from exc

    manifest_bytes = trusted_manifest.read_bytes()
    data = json.loads(manifest_bytes)
    expected = {}
    for row in data['files']:
        path = row['path']
        pp = PurePosixPath(path)
        if (not path or pp.is_absolute() or '..' in pp.parts or path != str(pp)
                or path in expected or path == 'MANIFEST_SHA256.json'):
            raise ReleaseCheckError('Unsafe, duplicate or self-referencing manifest path.')
        if not isinstance(row['bytes'], int) or row['bytes'] < 0:
            raise ReleaseCheckError('Invalid expected byte count.')
        if not re.fullmatch(r'[0-9a-f]{64}', row['sha256']):
            raise ReleaseCheckError('Invalid expected SHA-256.')
        expected[path] = (row['bytes'], row['sha256'])
    expected['MANIFEST_SHA256.json'] = (len(manifest_bytes), hashlib.sha256(manifest_bytes).hexdigest())

    entries = {}
    raw = git(checkout, 'ls-tree', '-r', '-z', '--full-tree', commit)
    for record in raw.split(b'\0'):
        if not record:
            continue
        head, path_b = record.split(b'\t', 1)
        mode, kind, oid = head.decode('ascii').split()
        path = path_b.decode('utf-8', errors='strict')
        if mode not in ('100644', '100755') or kind != 'blob':
            raise ReleaseCheckError(f'Non-regular file or submodule in pinned release: {path}')
        if path in entries:
            raise ReleaseCheckError('Duplicate Git path.')
        entries[path] = oid
    if set(entries) != set(expected):
        raise ReleaseCheckError('Pinned release file-set mismatch; missing=' +
                                repr(sorted(set(expected)-set(entries))) + '; extra=' +
                                repr(sorted(set(entries)-set(expected))))
    total = 0
    for path, oid in entries.items():
        blob = git(checkout, 'cat-file', 'blob', oid)
        total += len(blob)
        if (len(blob), hashlib.sha256(blob).hexdigest()) != expected[path]:
            raise ReleaseCheckError(f'Pinned release content mismatch: {path}')
    return dict(passed=True, commit=commit, requested_branch=branch, checked_local_ref=ref,
                branch_tip=tip, branch_contains_commit=True, exact_file_set=True,
                files_checked=len(entries), file_bytes_checked=total,
                trusted_manifest_sha256=hashlib.sha256(manifest_bytes).hexdigest(),
                git_replace_objects_disabled=True, public_availability_checked=False,
                independent_proof_checker=False, posted=False)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--checkout', type=Path, required=True)
    parser.add_argument('--branch', required=True)
    parser.add_argument('--commit', required=True)
    parser.add_argument('--trusted-manifest', type=Path,
                        default=Path(__file__).resolve().parents[1]/'MANIFEST_SHA256.json')
    parser.add_argument('--output', type=Path)
    a = parser.parse_args()
    try:
        report = verify_release(a.checkout, a.branch, a.commit, a.trusted_manifest)
        text = json.dumps(report, ensure_ascii=False, indent=2) + '\n'
        if a.output:
            a.output.parent.mkdir(parents=True, exist_ok=True)
            a.output.write_text(text)
        print(text, end='')
    except (ValueError, OSError, subprocess.SubprocessError, KeyError) as exc:
        parser.error(str(exc))


if __name__ == '__main__':
    main()
