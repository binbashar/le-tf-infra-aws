import io
import json
import os
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

from tofu_plan_ci.workflow import (
    layer_slug,
    read_backend_profile,
    run_aggregate,
    run_live,
    run_static,
)


class WorkflowTests(unittest.TestCase):
    def github_env(self, root: Path) -> dict[str, str]:
        return {
            "RUNNER_TEMP": str(root / "runner"),
            "GITHUB_WORKSPACE": str(root / "workspace"),
            "GITHUB_OUTPUT": str(root / "github-output"),
            "GITHUB_STEP_SUMMARY": str(root / "github-summary"),
            "GITHUB_REPOSITORY": "example/infrastructure",
            "GITHUB_SHA": "merge-sha",
            "GITHUB_RUN_ID": "42",
            "GITHUB_RUN_ATTEMPT": "1",
            "HEAD_SHA": "head-sha",
        }

    def test_layer_slug_matches_artifact_naming(self):
        self.assertEqual(
            layer_slug("apps-devstg/global/layer with spaces"),
            "apps-devstg-global-layer-with-spaces",
        )

    def test_backend_profile_accepts_only_the_expected_shape(self):
        with tempfile.TemporaryDirectory() as directory:
            backend = Path(directory) / "backend.tfvars"
            backend.write_text('region = "us-east-1"\nprofile = "ci_profile-1"\n')
            self.assertEqual(read_backend_profile(backend), "ci_profile-1")
            backend.write_text('profile = "bad/profile"\n')
            with self.assertRaises(ValueError):
                read_backend_profile(backend)

    def test_static_run_writes_outputs_summary_and_result(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            env = self.github_env(root)
            (root / "runner").mkdir()
            with patch.dict(os.environ, env, clear=True), patch(
                "tofu_plan_ci.workflow.run_logged", side_effect=[0, 0]
            ) as run:
                self.assertEqual(run_static("apps-devstg/global/cli-test-layer"), 0)

            self.assertEqual(run.call_count, 2)
            result = json.loads(
                next((root / "runner/tofu-plan-poc-report").rglob("result.json")).read_text()
            )
            self.assertEqual(result["status"], "passed")
            self.assertIn("report_dir=", (root / "github-output").read_text())
            self.assertIn("OpenTofu static validation", (root / "github-summary").read_text())

    def test_live_run_keeps_only_the_sanitized_report(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            workspace = root / "workspace"
            runner = root / "runner"
            (workspace / "config").mkdir(parents=True)
            account_config = workspace / "apps-devstg/config"
            account_config.mkdir(parents=True)
            (account_config / "backend.tfvars").write_text(
                'profile = "apps-devstg-ci"\n', encoding="utf-8"
            )
            (account_config / "account.tfvars").write_text("", encoding="utf-8")
            runner.mkdir()
            env = {
                **self.github_env(root),
                "COMMON_TFVARS": 'project = "example"',
                "AWS_ACCESS_KEY_ID": "temporary-access-key",
                "AWS_SECRET_ACCESS_KEY": "temporary-secret-key",
                "AWS_SESSION_TOKEN": "temporary-session-token",
                "AWS_REGION": "us-east-1",
                "POC_LAYER": "apps-devstg/global/cli-test-layer",
            }

            def fake_run(command, *, stdout_path, stderr_path=None, env=None):
                if "plan" in command:
                    return 2
                if "show" in command:
                    stdout_path.write_text(
                        json.dumps(
                            {
                                "format_version": "1.0",
                                "terraform_version": "1.9.1",
                                "resource_changes": [],
                            }
                        ),
                        encoding="utf-8",
                    )
                return 0

            with patch.dict(os.environ, env, clear=True), patch(
                "tofu_plan_ci.workflow.run_logged", side_effect=fake_run
            ):
                self.assertEqual(run_live("apps-devstg/global/cli-test-layer"), 0)

            report = next((runner / "tofu-plan-poc-report").rglob("result.json"))
            self.assertEqual(json.loads(report.read_text())["mode"], "live")
            self.assertTrue((report.parent / "review.json").is_file())
            self.assertFalse((workspace / "config/common.tfvars").exists())
            self.assertFalse(any(runner.glob("tofu-plan-apps-devstg-*")))
            self.assertFalse((runner / "aws").exists())
            self.assertFalse((runner / "tofu-plan-ui.jsonl").exists())

    def test_live_run_rejects_a_layer_outside_the_poc_allowlist(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            env = {
                **self.github_env(root),
                "POC_LAYER": "apps-devstg/global/cli-test-layer",
            }
            (root / "runner").mkdir()
            with patch.dict(os.environ, env, clear=True), redirect_stdout(io.StringIO()):
                self.assertEqual(run_live("security/us-east-1/security-audit"), 1)
            self.assertFalse((root / "runner/aws").exists())

    def test_aggregate_fails_when_an_expected_result_is_missing(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            discovery = root / "runner/tofu-plan-poc-discovery"
            discovery.mkdir(parents=True)
            (discovery / "discovery.json").write_text(
                json.dumps(
                    {
                        "layers": ["apps-devstg/global/cli-test-layer"],
                        "skipped": [],
                        "blocked_reason": None,
                    }
                ),
                encoding="utf-8",
            )
            with patch.dict(os.environ, self.github_env(root), clear=True), redirect_stdout(
                io.StringIO()
            ):
                self.assertEqual(run_aggregate(), 1)
            self.assertIn("Outcome:** FAIL", (root / "github-summary").read_text())


if __name__ == "__main__":
    unittest.main()
