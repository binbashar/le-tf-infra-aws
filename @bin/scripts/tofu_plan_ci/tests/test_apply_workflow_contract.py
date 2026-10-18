import re
import unittest
from pathlib import Path


def job(workflow: str, name: str) -> str:
    body = workflow.split(f"\n  {name}:\n", maxsplit=1)[1]
    return re.split(r"\n  [a-z_]+:\n", body, maxsplit=1)[0]


class ApplyWorkflowContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root = Path(__file__).resolve().parents[4]
        cls.workflow = (root / ".github/workflows/tofu-apply.yml").read_text()
        cls.plan_workflow = (root / ".github/workflows/tofu-plan.yml").read_text()
        cls.status_workflow = (root / ".github/workflows/tofu-apply-status.yml").read_text()

    def test_actions_are_pinned_to_full_commit_shas(self):
        for workflow in (self.workflow, self.status_workflow):
            references = re.findall(r"^\s*uses:\s+([^\s#]+)", workflow, re.MULTILINE)
            self.assertTrue(references)
            for reference in references:
                self.assertRegex(reference, r"@[0-9a-f]{40}$")

    def test_no_default_permissions(self):
        self.assertIn("\npermissions: {}\n", self.workflow)
        self.assertIn("\npermissions: {}\n", self.status_workflow)

    def test_comment_text_is_never_interpolated_into_a_script(self):
        self.assertIn("COMMENT_BODY: ${{ github.event.comment.body }}", self.workflow)
        steps = self.workflow.split("\njobs:\n", maxsplit=1)[1]
        for line in steps.splitlines():
            if "github.event.comment.body" in line:
                self.assertTrue("COMMENT_BODY:" in line or "startsWith(" in line, line)
        for line in self.workflow.splitlines():
            if line.strip().startswith("run:"):
                self.assertNotIn("${{", line)

    def test_only_the_apply_job_gets_aws_credentials(self):
        self.assertEqual(self.workflow.count("id-token: write"), 1)
        apply = job(self.workflow, "apply")
        self.assertIn("id-token: write", apply)
        self.assertIn("environment: tofu-apply\n", apply)
        self.assertNotIn("contents: write", apply)
        self.assertIn("allowed-account-ids: ${{ steps.identity.outputs.account_id }}", apply)
        self.assertIn("inline-session-policy: ${{ steps.identity.outputs.session_policy }}", apply)
        self.assertIn("mask-aws-account-id: true", apply)

    def test_apply_job_runs_pr_code_with_trusted_tooling(self):
        apply = job(self.workflow, "apply")
        self.assertIn("ref: ${{ needs.authorize.outputs.head_sha }}", apply)
        self.assertIn("PYTHONPATH: trusted/@bin/scripts", apply)
        order = [apply.index(step) for step in (
            "apply_workflow recheck", "apply_workflow credentials",
            "configure-aws-credentials", "apply_workflow apply")]
        self.assertEqual(order, sorted(order))

    def test_secrets_reach_only_the_apply_step(self):
        for secret in ("secrets.TOFU_PLAN_DIGEST_KEY", "secrets.TOFU_PLAN_COMMON_TFVARS"):
            self.assertEqual(self.workflow.count(secret), 1)
            self.assertIn(secret, job(self.workflow, "apply"))

    def test_ordinary_comments_never_share_the_command_queue(self):
        header = self.workflow.split("\npermissions: {}\n", maxsplit=1)[0]
        self.assertIn("startsWith(github.event.comment.body, '/tofu apply')", header)
        self.assertIn("format('-other-{0}', github.event.comment.id)", header)

    def test_unlock_needs_the_admin_environment(self):
        self.assertIn("environment: tofu-apply\n", job(self.workflow, "unlock"))

    def test_apply_is_serialized_per_layer(self):
        self.assertIn("group: tofu-apply-layer-${{ needs.authorize.outputs.slug }}",
                      job(self.workflow, "apply"))

    def test_github_token_never_posts_a_status(self):
        for workflow in (self.workflow, self.plan_workflow, self.status_workflow):
            self.assertNotRegex(workflow, r"\n\s+statuses: write")

    def test_the_status_app_key_is_used_only_in_its_environment(self):
        environment = "environment:\n      name: tofu-status\n      deployment: false\n"
        for workflow, name in ((self.workflow, "report"), (self.status_workflow, "status")):
            self.assertEqual(workflow.count("secrets.TOFU_STATUS_APP_PRIVATE_KEY"), 1)
            body = job(workflow, name)
            self.assertIn(environment, body)
            self.assertIn("secrets.TOFU_STATUS_APP_PRIVATE_KEY", body)
            self.assertIn("permission-statuses: write", body)

    def test_status_evidence_downloads_never_share_a_directory(self):
        paths = re.findall(r"path: (\$\{\{ runner.temp \}\}/tofu-plan-\S+)", self.status_workflow)
        self.assertEqual(len(paths), 3)
        self.assertEqual(len(set(paths)), 3)
        for first in paths:
            for second in paths:
                if first != second:
                    self.assertFalse(second.startswith(first + "/"), (first, second))

    def test_status_workflow_never_runs_pr_code(self):
        self.assertIn("pull_request_target:", self.status_workflow)
        self.assertNotIn("ref:", self.status_workflow)
        self.assertNotIn("head.sha }}\n", self.status_workflow.split("\njobs:\n", 1)[1])
        for line in self.status_workflow.splitlines():
            if line.strip().startswith("run:"):
                self.assertNotIn("${{", line)


if __name__ == "__main__":
    unittest.main()
