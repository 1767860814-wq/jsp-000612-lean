"""No network and no public writes; example references below are test data only."""
import importlib.util
import sys
import unittest
from pathlib import Path

root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('prepare_submission', root/'tools/prepare_submission.py')
m = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = m
spec.loader.exec_module(m)

class PrepareTests(unittest.TestCase):
    url = 'https://github.com/example-owner/example-proof'
    commit = 'ab'*20

    def test_valid(self):
        self.assertEqual(m.validate_reference(self.url, 'main', self.commit), (self.url, 'main', self.commit))
    def test_git_suffix(self):
        self.assertEqual(m.validate_reference(self.url+'.git', 'main', self.commit)[0], self.url)
    def test_uppercase_commit(self):
        self.assertEqual(m.validate_reference(self.url, 'main', self.commit.upper())[2], self.commit)
    def test_no_credentials(self):
        with self.assertRaises(ValueError): m.validate_reference('https://secret@github.com/a/b', 'main', self.commit)
    def test_no_wrong_host(self):
        with self.assertRaises(ValueError): m.validate_reference('https://github.com.evil/a/b', 'main', self.commit)
    def test_no_url_query(self):
        with self.assertRaises(ValueError): m.validate_reference(self.url+'?token=x', 'main', self.commit)
    def test_no_subpath(self):
        with self.assertRaises(ValueError): m.validate_reference(self.url+'/tree/main', 'main', self.commit)
    def test_no_shell_branch(self):
        with self.assertRaises(ValueError): m.validate_reference(self.url, 'main;echo hacked', self.commit)
    def test_no_traversal_branch(self):
        with self.assertRaises(ValueError): m.validate_reference(self.url, 'feature/../main', self.commit)
    def test_no_lock_branch(self):
        with self.assertRaises(ValueError): m.validate_reference(self.url, 'feature.lock/foo', self.commit)
    def test_no_sha256(self):
        with self.assertRaises(ValueError): m.validate_reference(self.url, 'main', m.PROOF_SHA256)
    def test_no_zero_commit(self):
        with self.assertRaises(ValueError): m.validate_reference(self.url, 'main', '0'*40)
    def test_no_short_commit(self):
        with self.assertRaises(ValueError): m.validate_reference(self.url, 'main', self.commit[:7])
    def test_templates_fully_render(self):
        for name in ['PR_BODY_EN.template.md','CATALOG_INSERT_EN.template.md']:
            result = m.render((root/'submission'/name).read_text(), self.url, 'main', self.commit)
            for token in m.TOKENS: self.assertNotIn(token, result)
            self.assertIn(self.commit, result)
    def test_patch_preserves_fields_and_neighbours(self):
        before = '## JSP-000611 · Previous\nPrevious\n\n## JSP-000612 · Target\n| Lean proof | No |\n| Eligible to claim | No |\n\n## JSP-000613 · Next\nNext\n'
        after = m.patch_catalogue(before, m.MARKER+'\nEvidence')
        self.assertIn('| Lean proof | No |\n| Eligible to claim | No |', after)
        self.assertTrue(after.startswith(before[:before.index('## JSP-000612')]))
        self.assertTrue(after.endswith('## JSP-000613 · Next\nNext\n'))
        self.assertEqual(after.count(m.MARKER), 1)
    def test_patch_missing_target(self):
        with self.assertRaises(ValueError): m.patch_catalogue('## JSP-000613\n', 'Evidence')
    def test_patch_duplicate_target(self):
        with self.assertRaises(ValueError): m.patch_catalogue('## JSP-000612\nA\n## JSP-000612\nB', 'Evidence')
    def test_patch_duplicate_evidence(self):
        with self.assertRaises(ValueError): m.patch_catalogue('## JSP-000612\n'+m.MARKER, 'Evidence')
    def test_reject_nonexistent_local_commit(self):
        with self.assertRaises(ValueError): m.verify_local_commit(root, self.commit)

if __name__ == '__main__': unittest.main()
