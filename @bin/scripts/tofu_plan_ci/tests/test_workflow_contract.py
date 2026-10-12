import re
import unittest
from pathlib import Path


class WorkflowSecurityContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root = Path(__file__).resolve().parents[4]
        cls.workflow = (root / ".github/workflows/tofu-plan.yml").read_text()

    def live_plan(self):
        return self.workflow.split("\n  live_plan:\n", maxsplit=1)[1].split(
            "\n  report:\n", maxsplit=1
        )[0]

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

    def test_plan_role_comes_from_trusted_resolution_with_session_policy(self):
        live_plan = self.live_plan()
        self.assertIn("python -m tofu_plan_ci.workflow credentials", live_plan)
        self.assertIn("role-to-assume: ${{ steps.identity.outputs.role_arn }}", live_plan)
        self.assertIn(
            "inline-session-policy: ${{ steps.identity.outputs.session_policy }}", live_plan
        )
        self.assertIn("PYTHONPATH: trusted/@bin/scripts", live_plan)
        self.assertLess(
            live_plan.index("workflow credentials"), live_plan.index("configure-aws-credentials")
        )

    def test_bedrock_runs_in_the_plan_job_after_the_plan_role_is_cleared(self):
        live_plan = self.live_plan()
        self.assertIn("environment: tofu-plan\n", live_plan)
        self.assertNotIn("tofu-plan-bedrock", self.workflow)
        self.assertNotIn("\n  analysis:\n", self.workflow)
        plan_step = live_plan.index("python -m tofu_plan_ci.workflow live")
        bedrock_role = live_plan.index("role-to-assume: ${{ vars.AWS_TOFU_PLAN_BEDROCK_ROLE_ARN }}")
        explainer = live_plan.index("workflow llm --kind explainer")
        security = live_plan.index("workflow llm --kind security")
        cleanup = live_plan.index("workflow llm-cleanup")
        self.assertLess(plan_step, bedrock_role)
        self.assertLess(bedrock_role, explainer)
        self.assertLess(explainer, security)
        self.assertLess(security, cleanup)
        cleanup_step = live_plan[live_plan.rindex("- name:", 0, cleanup) : cleanup]
        self.assertIn("if: ${{ always() }}", cleanup_step)

    def test_each_analysis_has_its_own_kill_switch(self):
        live_plan = self.live_plan()
        self.assertIn("vars.TOFU_PLAN_LLM_EXPLAINER == 'true' }}", live_plan)
        self.assertIn("vars.TOFU_PLAN_LLM_SECURITY == 'true' }}", live_plan)
        self.assertNotIn("vars.TOFU_PLAN_LLM ==", self.workflow)

    def test_llm_artifacts_do_not_match_the_plan_evidence_pattern(self):
        self.assertIn("name: tofu-plan-llm-${{ steps.run.outputs.slug }}", self.workflow)
        self.assertIn("pattern: tofu-plan-layer-*", self.workflow)
        self.assertIn("pattern: tofu-plan-llm-*", self.workflow)

    def test_report_receives_head_sha_for_artifact_provenance(self):
        report = self.workflow.split("\n  report:\n", maxsplit=1)[1]
        self.assertIn(
            "HEAD_SHA: ${{ github.event.pull_request.head.sha || github.sha }}",
            report,
        )

    def test_evidence_uploads_require_a_report_directory(self):
        self.assertEqual(
            self.workflow.count("steps.run.outputs.report_dir != ''"),
            2,
        )


if __name__ == "__main__":
    unittest.main()
