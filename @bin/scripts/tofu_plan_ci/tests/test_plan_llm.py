import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tofu_plan_ci import plan_llm

SHOW_TEXT = """
module.permission_sets.data.aws_ssoadmin_instances.this: Reading...

OpenTofu used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

OpenTofu will perform the following actions:

  # aws_iam_policy.example will be updated in-place
  ~ resource "aws_iam_policy" "example" {
      ~ policy = jsonencode(
          ~ {
              ~ Statement = [
                  + "arn:aws:iam::123456789012:role/Example",
                  + "arn:aws:sso:::instance/ssoins-72236b1f0a1b2c3d",
                ]
            }
        )
        tags   = {
            "Owner" = "someone@example.com"
        }
    }

Plan: 0 to add, 1 to change, 0 to destroy.

Changes to Outputs:
  ~ role_arn = "arn:aws:iam::123456789012:role/Example"
"""

EXPLAINER = {
    "summary": ["Adds a statement to one policy."],
    "changes": [
        {
            "resource": "aws_iam_policy.example",
            "action": "update",
            "description": "Grants access; contact someone@example.com",
        }
    ],
    "notes": [],
}

SECURITY = {
    "overall_risk": "medium",
    "findings": [
        {
            "severity": "medium",
            "resource": "aws_iam_policy.example",
            "issue": "Broader <b>permissions</b>",
            "evidence": "Statement adds a role",
            "recommendation": "Scope it.",
        }
    ],
    "limitations": ["Sensitive values are hidden."],
}


class PlanTextTests(unittest.TestCase):
    def test_action_section_stops_at_the_plan_summary(self):
        section = plan_llm.action_section(SHOW_TEXT)
        self.assertTrue(section.startswith("OpenTofu will perform the following actions:"))
        self.assertTrue(section.rstrip().endswith("Plan: 0 to add, 1 to change, 0 to destroy."))
        self.assertNotIn("Reading...", section)
        self.assertNotIn("Changes to Outputs", section)

    def test_prepared_text_is_redacted(self):
        text = plan_llm.prepare_plan_text(SHOW_TEXT)
        self.assertNotIn("123456789012", text)
        self.assertNotIn("ssoins-72236b1f0a1b2c3d", text)
        self.assertIn("<ACCOUNT_NAME_ACCOUNT_ID>", text)
        # E-mail addresses reach the model by decision; outputs are masked instead.
        self.assertIn("someone@example.com", text)

    def test_no_changes_and_oversized_plans_are_not_sent(self):
        with self.assertRaisesRegex(plan_llm.PlanUnavailable, "no-changes"):
            plan_llm.prepare_plan_text("No changes. Your infrastructure matches the configuration.")
        with patch.object(plan_llm, "MAX_INPUT_TOKENS", 10):
            with self.assertRaisesRegex(plan_llm.PlanUnavailable, "too-large"):
                plan_llm.prepare_plan_text(SHOW_TEXT)


class AnswerTests(unittest.TestCase):
    def test_valid_answers_pass_and_invalid_ones_fail(self):
        plan_llm.validate("explainer", EXPLAINER)
        plan_llm.validate("security", SECURITY)
        for kind, answer in (
            ("explainer", {"summary": []}),
            ("explainer", {**EXPLAINER, "changes": [{"resource": "x", "action": "move", "description": "y"}]}),
            ("security", {**SECURITY, "overall_risk": "unknown"}),
            ("security", {**SECURITY, "findings": [{"severity": "low"}]}),
        ):
            with self.subTest(kind=kind, answer=answer), self.assertRaises(ValueError):
                plan_llm.validate(kind, answer)

    def test_rendering_masks_and_escapes_model_text(self):
        explainer = plan_llm.render_markdown(
            "explainer", EXPLAINER, layer="apps-devstg/global/x", model_id="m"
        )
        security = plan_llm.render_markdown(
            "security", SECURITY, layer="apps-devstg/global/x", model_id="m"
        )
        self.assertNotIn("someone@example.com", explainer)
        self.assertIn("&lt;email&gt;", explainer)
        self.assertIn("&lt;b&gt;permissions&lt;/b&gt;", security)
        self.assertIn("Advisory only", security)

    def test_run_writes_markdown_and_status(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(
            plan_llm.bedrock_client,
            "invoke_tool",
            return_value=(SECURITY, {"inputTokens": 1200, "outputTokens": 300}),
        ) as invoke:
            out_dir = Path(directory)
            status = plan_llm.run(
                "security",
                plan_text="OpenTofu will perform the following actions:\n",
                layer="apps-devstg/global/x",
                model_id="us.anthropic.claude-haiku-5-5",
                region="us-east-1",
                request_metadata={},
                out_dir=out_dir,
            )
            self.assertEqual(status["overall_risk"], "medium")
            self.assertEqual(status["findings"], 1)
            self.assertTrue((out_dir / "security.md").is_file())
            self.assertEqual(json.loads((out_dir / "security.json").read_text())["status"], "success")
            self.assertIn("<plan>", invoke.call_args.kwargs["user_text"])
            self.assertEqual(invoke.call_args.kwargs["tool_name"], "review_tofu_plan_security")


if __name__ == "__main__":
    unittest.main()
