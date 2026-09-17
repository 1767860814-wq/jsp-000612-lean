"""Offline adversarial release-reference tests. No public repository is created."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from tools.release_gate import verify_release, ReleaseCheckError


class ReleaseGateTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='jsp612-release-test-')
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.repo = self.base/'repo'
        self.repo.mkdir()
        self.git('init', '-q', '-b', 'main')
        self.git('config', 'user.name', 'Local verification test')
        self.git('config', 'user.email', 'test@example.invalid')
        self.git('config', 'commit.gpgsign', 'false')
        files = {'JSP000612.lean': b'-- test fixture, not the mathematical proof\n',
                 'tools/support.py': b'print("fixture")\n', 'README.md': b'Fixture\n'}
        rows = []
        for name, body in sorted(files.items()):
            p = self.repo/name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(body)
            rows.append(dict(path=name, bytes=len(body), sha256=hashlib.sha256(body).hexdigest()))
        text = json.dumps({'files': rows}, indent=2).encode()
        (self.repo/'MANIFEST_SHA256.json').write_bytes(text)
        self.trusted = self.base/'trusted-manifest.json'
        self.trusted.write_bytes(text)
        self.good = self.commit()

    def git(self, *args):
        return subprocess.run(['git', '-C', str(self.repo), *args], check=True,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout.decode().strip()

    def commit(self):
        self.git('add', '-A')
        self.git('commit', '-q', '--allow-empty', '-m', 'local test only')
        return self.git('rev-parse', 'HEAD')

    def check(self, commit=None, branch='main'):
        return verify_release(self.repo, branch, commit or self.good, self.trusted)

    def test_exact_release_passes(self):
        r = self.check()
        self.assertEqual(r['files_checked'], 4)
        self.assertTrue(r['branch_contains_commit'])
        self.assertFalse(r['public_availability_checked'])
        self.assertFalse(r['independent_proof_checker'])

    def test_branch_ahead_still_contains_pinned_commit(self):
        (self.repo/'unreviewed').write_text('A later change is not the pinned release.')
        self.commit()
        self.assertTrue(self.check()['passed'])

    def test_missing_branch_rejected(self):
        with self.assertRaisesRegex(ReleaseCheckError, 'branch is not available'):
            self.check(branch='does-not-exist')

    def test_branch_not_containing_pin_rejected(self):
        self.git('checkout', '-q', '--orphan', 'unrelated')
        (self.repo/'README.md').write_text('unrelated branch history\n')
        unrelated = self.commit()
        self.assertNotEqual(unrelated, self.good)
        with self.assertRaisesRegex(ReleaseCheckError, 'does not contain'):
            self.check(branch='unrelated')

    def test_remote_tracking_branch_supported_but_not_public_certified(self):
        self.git('update-ref', 'refs/remotes/origin/review', self.good)
        r = self.check(branch='review')
        self.assertEqual(r['checked_local_ref'], 'refs/remotes/origin/review')
        self.assertFalse(r['public_availability_checked'])

    def test_invalid_branch_syntax_rejected(self):
        with self.assertRaises(ReleaseCheckError): self.check(branch='main..evil')

    def test_invalid_commit_syntax_rejected(self):
        with self.assertRaises(ReleaseCheckError): self.check(commit=self.good[:7])

    def test_non_commit_object_rejected(self):
        tree = self.git('rev-parse', 'HEAD^{tree}')
        with self.assertRaisesRegex(ReleaseCheckError, 'not a commit'):
            self.check(commit=tree)

    def test_missing_commit_rejected(self):
        with self.assertRaises(ReleaseCheckError): self.check(commit='1'*40)

    def test_changed_proof_rejected(self):
        (self.repo/'JSP000612.lean').write_text('axiom false_claim : False\n')
        bad = self.commit()
        with self.assertRaisesRegex(ReleaseCheckError, 'content mismatch'):
            self.check(commit=bad)

    def test_unchanged_proof_changed_checker_rejected(self):
        (self.repo/'tools/support.py').write_text('print("fake pass")\n')
        bad = self.commit()
        with self.assertRaisesRegex(ReleaseCheckError, 'content mismatch'):
            self.check(commit=bad)

    def test_missing_file_rejected(self):
        (self.repo/'README.md').unlink()
        bad = self.commit()
        with self.assertRaisesRegex(ReleaseCheckError, 'file-set mismatch'):
            self.check(commit=bad)

    def test_extra_compiled_cache_rejected(self):
        (self.repo/'JSP000612.olean').write_bytes(b'not reviewed')
        bad = self.commit()
        with self.assertRaisesRegex(ReleaseCheckError, 'file-set mismatch'):
            self.check(commit=bad)

    def test_symlink_rejected(self):
        (self.repo/'README.md').unlink()
        (self.repo/'README.md').symlink_to('JSP000612.lean')
        bad = self.commit()
        with self.assertRaisesRegex(ReleaseCheckError, 'Non-regular'):
            self.check(commit=bad)

    def test_rewritten_candidate_manifest_rejected(self):
        (self.repo/'MANIFEST_SHA256.json').write_text('{"files": []}\n')
        bad = self.commit()
        with self.assertRaisesRegex(ReleaseCheckError, 'content mismatch'):
            self.check(commit=bad)

    def test_uncommitted_changes_do_not_replace_pinned_blobs(self):
        (self.repo/'JSP000612.lean').write_text('dirty working tree, not pinned\n')
        self.assertTrue(self.check()['passed'])

    def test_git_replace_cannot_hide_bad_release(self):
        (self.repo/'README.md').write_text('bad pinned version\n')
        bad = self.commit()
        self.git('replace', bad, self.good)
        with self.assertRaises(ReleaseCheckError): self.check(commit=bad)

    def test_trusted_manifest_traversal_rejected(self):
        body = json.loads(self.trusted.read_text())
        body['files'][0]['path'] = '../escape'
        self.trusted.write_text(json.dumps(body))
        with self.assertRaisesRegex(ReleaseCheckError, 'Unsafe'):
            self.check()


if __name__ == '__main__':
    unittest.main()
