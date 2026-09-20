import re
import unittest
from pathlib import Path


class WorkflowSecurityContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root = Path(__file__).resolve().parents[4]
        cls.workflow = (root / ".github/workflows/tofu-plan-poc.yml").read_text()

    def test_actions_are_pinned_to_full_commit_shas(self):
        references = re.findall(r"^\s*uses:\s+([^\s#]+)", self.workflow, re.MULTILINE)
        self.assertTrue(references)
        for reference in references:
            self.assertRegex(reference, r"@[0-9a-f]{40}$")

    def test_internal_pr_boundary_is_visible(self):
        for expected in (
            "head.repo.full_name == github.repository",
            "github.event.pull_request.user.type == 'User'",
            "github.event.pull_request.draft == false",
        ):
            self.assertIn(expected, self.workflow)
        self.assertNotIn("author_association", self.workflow)

    def test_credential_jobs_use_account_and_session_guards(self):
        self.assertIn("allowed-account-ids:", self.workflow)
        self.assertEqual(self.workflow.count("role-duration-seconds: 900"), 2)
        self.assertEqual(self.workflow.count("mask-aws-account-id: true"), 2)
        self.assertIn("needs.discover.outputs.live_eligible == 'true'", self.workflow)


if __name__ == "__main__":
    unittest.main()
