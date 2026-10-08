import unittest

from tofu_plan_ci.aggregate import aggregate, render_markdown


class AggregateTests(unittest.TestCase):
    def discovery(self):
        return {
            "schema_version": 1,
            "layers": ["apps-devstg/global/cli-test-layer"],
            "skipped": [],
            "blocked_reason": None,
        }

    def result(self, *, mode="live", status="passed"):
        return {
            "schema_version": 1,
            "layer": "apps-devstg/global/cli-test-layer",
            "mode": mode,
            "status": status,
            "summary": {"create": 1, "update": 0, "delete": 0, "replace": 0},
            "metadata": {
                "repository": "example/infrastructure",
                "head_sha": "head-sha",
                "run_id": "42",
            },
        }

    def test_live_success_passes(self):
        gate, reasons = aggregate(
            discovery=self.discovery(), results=[self.result()], require_live=True
        )
        self.assertEqual(gate, "pass")
        self.assertEqual(reasons, [])

    def test_static_result_fails_when_live_is_required(self):
        gate, reasons = aggregate(
            discovery=self.discovery(),
            results=[self.result(mode="static")],
            require_live=True,
        )
        self.assertEqual(gate, "fail")
        self.assertIn("live plan required", reasons[0])

    def test_missing_result_cannot_be_an_all_clear(self):
        gate, reasons = aggregate(
            discovery=self.discovery(), results=[], require_live=False
        )
        self.assertEqual(gate, "fail")
        self.assertIn("missing result", reasons[0])

    def test_artifact_from_another_run_fails_closed(self):
        gate, reasons = aggregate(
            discovery=self.discovery(),
            results=[self.result()],
            require_live=True,
            expected_metadata={
                "repository": "example/infrastructure",
                "head_sha": "different-head",
                "run_id": "42",
            },
        )
        self.assertEqual(gate, "fail")
        self.assertTrue(any("provenance" in reason for reason in reasons))

    def test_summary_makes_static_mode_explicit(self):
        markdown = render_markdown(
            discovery=self.discovery(),
            results=[self.result(mode="static")],
            gate="pass",
            reasons=[],
            require_live=False,
            analysis_markdown=None,
            analysis_status="disabled",
        )
        self.assertIn("Live planning is not enabled", markdown)
        self.assertIn("init -backend=false", markdown)


if __name__ == "__main__":
    unittest.main()
