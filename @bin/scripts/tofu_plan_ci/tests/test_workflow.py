import io
import json
import os
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

from tofu_plan_ci import workflow
from tofu_plan_ci.workflow import (
    allowed_layers,
    common_tfvars_shape,
    layer_slug,
    read_backend_profile,
    run_aggregate,
    run_credentials,
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

    def test_allowed_layers_accepts_comma_and_newline_separators(self):
        value = " apps-devstg/global/cli-test-layer,\nmanagement/global/sso\n\n"
        with patch.dict(os.environ, {"PLAN_LAYERS": value}, clear=True):
            self.assertEqual(
                allowed_layers(),
                ["apps-devstg/global/cli-test-layer", "management/global/sso"],
            )

    def test_allowed_layers_rejects_an_empty_list(self):
        with patch.dict(os.environ, {"PLAN_LAYERS": " , \n"}, clear=True):
            with self.assertRaises(ValueError):
                allowed_layers()

    def test_backend_profile_accepts_only_the_expected_shape(self):
        with tempfile.TemporaryDirectory() as directory:
            backend = Path(directory) / "backend.tfvars"
            backend.write_text('region = "us-east-1"\nprofile = "ci_profile-1"\n')
            self.assertEqual(read_backend_profile(backend), "ci_profile-1")
            backend.write_text('profile = "bad/profile"\n')
            with self.assertRaises(ValueError):
                read_backend_profile(backend)

    def test_common_tfvars_shape_excludes_values(self):
        shape = common_tfvars_shape('accounts = {\n  security = { id = "secret" }\n}\n')
        self.assertEqual(shape, "accounts=present;accounts.security=present")
        self.assertNotIn("secret", shape)

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
            for call in run.call_args_list:
                self.assertEqual(
                    call.kwargs["cwd"].resolve(),
                    (root / "workspace/apps-devstg/global/cli-test-layer").resolve(),
                )
                self.assertFalse(any(argument.startswith("-chdir=") for argument in call.args[0]))
            result = json.loads(
                next((root / "runner/tofu-plan-report").rglob("result.json")).read_text()
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
                "PLAN_LAYERS": "apps-devstg/global/cli-test-layer",
            }

            def fake_run(command, *, stdout_path, stderr_path=None, env=None, cwd=None):
                self.assertEqual(
                    cwd.resolve(),
                    (workspace / "apps-devstg/global/cli-test-layer").resolve(),
                )
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

            report = next((runner / "tofu-plan-report").rglob("result.json"))
            self.assertEqual(json.loads(report.read_text())["mode"], "live")
            self.assertTrue((report.parent / "review.json").is_file())
            self.assertFalse((workspace / "config/common.tfvars").exists())
            self.assertFalse(any(runner.glob("tofu-plan-apps-devstg-*")))
            self.assertFalse((runner / "aws").exists())
            self.assertFalse((runner / "tofu-plan-ui.jsonl").exists())

    def live_run_for_digest(self, root: Path, extra_env: dict[str, str]) -> tuple[dict, list]:
        workspace = root / "workspace"
        runner = root / "runner"
        (workspace / "config").mkdir(parents=True)
        account_config = workspace / "apps-devstg/config"
        account_config.mkdir(parents=True)
        (account_config / "backend.tfvars").write_text('profile = "apps-devstg-ci"\n')
        (account_config / "account.tfvars").write_text("")
        runner.mkdir()
        env = {
            **self.github_env(root),
            "COMMON_TFVARS": 'project = "example"',
            "AWS_ACCESS_KEY_ID": "temporary-access-key",
            "AWS_SECRET_ACCESS_KEY": "temporary-secret-key",
            "AWS_SESSION_TOKEN": "temporary-session-token",
            "PLAN_LAYERS": "apps-devstg/global/cli-test-layer",
            **extra_env,
        }
        subprocess_envs = []

        def fake_run(command, *, stdout_path, stderr_path=None, env=None, cwd=None):
            subprocess_envs.append(env)
            if "plan" in command:
                return 2
            if "show" in command:
                stdout_path.write_text(
                    json.dumps(
                        {
                            "format_version": "1.0",
                            "resource_changes": [
                                {"address": "aws_iam_role.x", "change": {"actions": ["create"], "after": {"name": "x"}}}
                            ],
                        }
                    )
                )
            return 0

        with patch.dict(os.environ, env, clear=True), patch(
            "tofu_plan_ci.workflow.run_logged", side_effect=fake_run
        ), redirect_stdout(io.StringIO()):
            self.assertEqual(run_live("apps-devstg/global/cli-test-layer"), 0)
        report = next((runner / "tofu-plan-report").rglob("result.json"))
        return json.loads(report.read_text()), subprocess_envs

    def test_live_run_records_a_plan_digest_without_exposing_the_key(self):
        key = "digest-key-" + "x" * 32
        with tempfile.TemporaryDirectory() as directory:
            result, envs = self.live_run_for_digest(Path(directory), {"PLAN_DIGEST_KEY": key})
        self.assertRegex(result["plan_digest"], r"\Ahmac-sha256:v1:[0-9a-f]{64}\Z")
        self.assertTrue(envs)
        for env in envs:
            self.assertNotIn("PLAN_DIGEST_KEY", env)
            self.assertNotIn(key, env.values())

    def test_live_run_without_a_key_has_no_digest(self):
        with tempfile.TemporaryDirectory() as directory:
            result, _ = self.live_run_for_digest(Path(directory), {})
        self.assertIsNone(result["plan_digest"])

    def live_run_with_llm(self, root: Path, show_text: str) -> tuple[str, str]:
        workspace = root / "workspace"
        runner = root / "runner"
        (workspace / "config").mkdir(parents=True)
        account_config = workspace / "apps-devstg/config"
        account_config.mkdir(parents=True)
        (account_config / "backend.tfvars").write_text('profile = "apps-devstg-ci"\n')
        (account_config / "account.tfvars").write_text("")
        runner.mkdir()
        env = {
            **self.github_env(root),
            "COMMON_TFVARS": 'project = "example"',
            "AWS_ACCESS_KEY_ID": "temporary-access-key",
            "AWS_SECRET_ACCESS_KEY": "temporary-secret-key",
            "AWS_SESSION_TOKEN": "temporary-session-token",
            "PLAN_LAYERS": "apps-devstg/global/cli-test-layer",
            "LLM_ENABLED": "true",
        }

        def fake_run(command, *, stdout_path, stderr_path=None, env=None, cwd=None):
            if "plan" in command:
                return 2
            if "-json" in command:
                stdout_path.write_text(
                    json.dumps({"format_version": "1.0", "resource_changes": []})
                )
            elif "show" in command:
                stdout_path.write_text(show_text)
            return 0

        output = io.StringIO()
        with patch.dict(os.environ, env, clear=True), patch(
            "tofu_plan_ci.workflow.run_logged", side_effect=fake_run
        ), redirect_stdout(output):
            self.assertEqual(run_live("apps-devstg/global/cli-test-layer"), 0)
        return (root / "github-output").read_text(), output.getvalue()

    def test_live_run_writes_redacted_plan_text_for_the_llm(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            outputs, _ = self.live_run_with_llm(
                root,
                "OpenTofu will perform the following actions:\n"
                '  + role = "arn:aws:iam::123456789012:role/x"\n'
                "Plan: 1 to add, 0 to change, 0 to destroy.\n",
            )
            self.assertIn("llm_input=ready", outputs)
            text = root / "runner" / "tofu-plan-llm-input-apps-devstg-global-cli-test-layer.txt"
            self.assertNotIn("123456789012", text.read_text())
            self.assertEqual(text.stat().st_mode & 0o777, 0o600)
            self.assertFalse(any((root / "runner").glob("tofu-show-*")))

    def test_live_run_says_why_there_is_no_analysis(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            outputs, printed = self.live_run_with_llm(
                root, "No changes. Your infrastructure matches the configuration.\n"
            )
            self.assertIn("llm_input=no-changes", outputs)
            self.assertIn("::notice::No LLM analysis", printed)
            self.assertIn("the plan has no changes", (root / "github-summary").read_text())

    def test_live_run_rejects_a_layer_outside_the_allowlist(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            env = {
                **self.github_env(root),
                "PLAN_LAYERS": "apps-devstg/global/cli-test-layer",
            }
            (root / "runner").mkdir()
            with patch.dict(os.environ, env, clear=True), redirect_stdout(io.StringIO()):
                self.assertEqual(run_live("security/us-east-1/security-audit"), 1)
            self.assertFalse((root / "runner/aws").exists())

    def test_credentials_emit_role_and_session_policy_for_an_allowlisted_layer(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            workspace = root / "workspace"
            (workspace / "management/config").mkdir(parents=True)
            (workspace / "management/global/sso").mkdir(parents=True)
            (workspace / "management/config/backend.tfvars").write_text(
                'bucket = "mgmt-state"\nregion = "us-east-1"\ndynamodb_table = "mgmt-lock"\n'
            )
            (workspace / "management/global/sso/config.tf").write_text(
                'terraform {\n  backend "s3" {\n    key = "management/sso/terraform.tfstate"\n  }\n}\n'
            )
            env = {
                **self.github_env(root),
                "PLAN_LAYERS": "apps-devstg/global/cli-test-layer,management/global/sso",
                "TOFU_PLAN_ROLES": json.dumps(
                    {
                        "management": {
                            "role_arn": "arn:aws:iam::111111111111:role/GitHubActionsOpenTofuPlan",
                            "account_id": "111111111111",
                        }
                    }
                ),
            }
            with patch.dict(os.environ, env, clear=True), redirect_stdout(io.StringIO()) as out:
                self.assertEqual(run_credentials("management/global/sso"), 0)
                self.assertEqual(run_credentials("security/global/base-identities"), 1)
            self.assertIn("::add-mask::111111111111", out.getvalue())
            outputs = (root / "github-output").read_text()
            self.assertIn("role_arn=arn:aws:iam::111111111111:role/GitHubActionsOpenTofuPlan", outputs)
            self.assertIn("session_policy={", outputs)

    def test_aggregate_fails_when_an_expected_result_is_missing(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            discovery = root / "runner/tofu-plan-discovery"
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


class LlmStepTests(unittest.TestCase):
    def test_a_bedrock_failure_warns_without_details_and_never_fails(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(
            os.environ, {"RUNNER_TEMP": directory}
        ), patch.object(
            workflow.plan_llm, "run", side_effect=RuntimeError("secret detail someone@example.com")
        ), patch("builtins.print") as printed:
            (Path(directory) / "tofu-plan-llm-input-apps-devstg-global-x.txt").write_text("plan")
            self.assertEqual(workflow.run_llm("apps-devstg/global/x", "security"), 0)
            status = json.loads(
                (Path(directory) / "tofu-plan-llm" / "apps-devstg-global-x" / "security.json").read_text()
            )
        self.assertEqual(status["status"], "failed")
        output = " ".join(str(call.args) for call in printed.call_args_list)
        self.assertIn("RuntimeError", output)
        self.assertNotIn("secret detail", output)

    def test_cleanup_removes_the_plan_text(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(
            os.environ, {"RUNNER_TEMP": directory, "GITHUB_ENV": str(Path(directory) / "env")}
        ):
            plan_text = Path(directory) / "tofu-plan-llm-input-apps-devstg-global-x.txt"
            plan_text.write_text("plan")
            workflow.run_llm_cleanup("apps-devstg/global/x")
            self.assertFalse(plan_text.exists())
            self.assertIn("AWS_SESSION_TOKEN=", (Path(directory) / "env").read_text())
