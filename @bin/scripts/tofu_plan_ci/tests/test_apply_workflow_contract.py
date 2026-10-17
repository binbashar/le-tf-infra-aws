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

    def test_actions_are_pinned_to_full_commit_shas(self):
        references = re.findall(r"^\s*uses:\s+([^\s#]+)", self.workflow, re.MULTILINE)
        self.assertTrue(references)
        for reference in references:
            self.assertRegex(reference, r"@[0-9a-f]{40}$")

    def test_no_default_permissions(self):
        self.assertIn("\npermissions: {}\n", self.workflow)

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

    def test_status_tooling_comes_from_the_base_revision(self):
        report = self.plan_workflow.split("\n  report:\n", maxsplit=1)[1]
        step = report[report.index("Set the OpenTofu Apply status"):]
        self.assertIn("PYTHONPATH: status-trusted/@bin/scripts", step)
        self.assertIn("ref: ${{ github.event.pull_request.base.sha }}\n          path: status-trusted",
                      report)

    def test_unlock_needs_the_admin_environment(self):
        self.assertIn("environment: tofu-apply\n", job(self.workflow, "unlock"))

    def test_apply_is_serialized_per_layer(self):
        self.assertIn("group: tofu-apply-layer-${{ needs.authorize.outputs.slug }}",
                      job(self.workflow, "apply"))

    def test_plan_report_posts_the_apply_status_without_failing_the_plan(self):
        report = self.plan_workflow.split("\n  report:\n", maxsplit=1)[1]
        self.assertIn("statuses: write", report)
        step = report[report.index("Set the OpenTofu Apply status"):]
        self.assertIn("continue-on-error: true", step)
        self.assertIn("apply_workflow plan-status", step)


if __name__ == "__main__":
    unittest.main()
