import io
import json
import os
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

from tofu_plan_ci import apply_workflow
from tofu_plan_ci.apply_gates import lock_message
from tofu_plan_ci.github_api import GitHub
from tofu_plan_ci.plan_digest import plan_digest

KEY = "digest-key-" + "x" * 32
LAYER = "apps-devstg/global/cli-test-layer"
HEAD = "a" * 40
REPO = "example/infrastructure"
PLAN = {
    "format_version": "1.0",
    "resource_changes": [
        {"address": "aws_iam_policy.leverage_test", "change": {"actions": ["create"], "after": {"name": "x"}}}
    ],
}


class FakeGitHub:
    def __init__(self, *, pr=None, permission="write", reviews=None, behind=0, runs=None, locks=None):
        self._pr = pr or {
            "number": 7, "state": "open", "draft": False,
            "user": {"login": "author", "type": "User"},
            "head": {"sha": HEAD, "repo": {"full_name": REPO}}, "base": {"ref": "master"},
        }
        self._permission = permission
        self._reviews = reviews if reviews is not None else [
            {"user": {"login": "reviewer"}, "state": "APPROVED", "commit_id": HEAD}]
        self._behind = behind
        self._runs = runs if runs is not None else [
            {"id": 11, "head_sha": HEAD, "event": "pull_request", "run_number": 1,
             "status": "completed", "conclusion": "success"}]
        self.locks = dict(locks or {})
        self.comments, self.statuses, self.reactions, self.deleted = [], [], [], []

    def pull(self, number): return self._pr
    def permission(self, user): return self._permission
    def reviews(self, number): return self._reviews
    def compare(self, base, head): return {"behind_by": self._behind}
    def workflow_runs(self, workflow, head_sha): return self._runs
    def react(self, comment_id, content): self.reactions.append(content)
    def comment(self, number, body): self.comments.append(body)
    def status(self, sha, **kwargs): self.statuses.append((sha, kwargs))
    def delete_ref(self, ref): self.deleted.append(ref); self.locks.pop(ref, None)

    def matching_refs(self, prefix):
        return [{"ref": ref, "object": {"type": "tag", "sha": ref}} for ref in self.locks
                if ref.startswith(f"refs/{prefix}")]

    def tag(self, sha):
        return {"message": self.locks[sha]}


class ApplyWorkflowTestCase(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name)
        (self.root / "runner").mkdir()
        self.env = {
            "RUNNER_TEMP": str(self.root / "runner"),
            "GITHUB_OUTPUT": str(self.root / "github-output"),
            "GITHUB_STEP_SUMMARY": str(self.root / "summary"),
            "GITHUB_ENV": str(self.root / "github-env"),
            "GITHUB_REPOSITORY": REPO,
            "GITHUB_RUN_ID": "99",
            "GH_TOKEN": "token",
            "PR_NUMBER": "7",
            "APPLY_LAYERS": LAYER,
        }

    def tearDown(self):
        self.directory.cleanup()

    def outputs(self) -> dict[str, str]:
        path = self.root / "github-output"
        if not path.exists():
            return {}
        return dict(line.split("=", 1) for line in path.read_text().splitlines())

    def state(self, name):
        return json.loads((self.root / "runner" / "tofu-apply" / name).read_text())


class RunApplyTests(ApplyWorkflowTestCase):
    def run_apply(self, *, plan=PLAN, reviewed=None, plan_exit=2, apply_exit=0, extra=None):
        workspace = self.root / "workspace"
        (workspace / "config").mkdir(parents=True)
        account = workspace / "apps-devstg" / "config"
        account.mkdir(parents=True)
        (account / "backend.tfvars").write_text('profile = "apps-devstg-ci"\n')
        (account / "account.tfvars").write_text("")
        env = {
            **self.env,
            "CANDIDATE_ROOT": str(workspace),
            "COMMON_TFVARS": 'project = "example"',
            "PLAN_DIGEST_KEY": KEY,
            "REVIEWED_DIGEST": reviewed or plan_digest(plan, KEY),
            "AWS_ACCESS_KEY_ID": "temporary-access-key",
            "AWS_SECRET_ACCESS_KEY": "temporary-secret-key",
            "AWS_SESSION_TOKEN": "temporary-session-token",
            **(extra or {}),
        }
        self.commands, self.envs = [], []

        def fake_run(command, *, stdout_path, stderr_path=None, env=None, cwd=None):
            self.commands.append(command[1])
            self.envs.append(env)
            if command[1] == "plan":
                return plan_exit
            if command[1] == "show":
                stdout_path.write_text(json.dumps(plan))
            if command[1] == "apply":
                marker = self.root / "runner" / "tofu-apply" / "result.json"
                self.marker_before_apply = json.loads(marker.read_text())
                stdout_path.write_text(json.dumps({"type": "change_summary", "changes": {
                    "add": 1, "change": 0, "remove": 0, "operation": "apply"}}) + "\n")
                return apply_exit
            return 0

        with patch.dict(os.environ, env, clear=True), patch(
            "tofu_plan_ci.workflow.run_logged", side_effect=fake_run
        ), redirect_stdout(io.StringIO()):
            code = apply_workflow.run_apply(LAYER)
        return code, self.state("result.json")

    def test_matching_plan_is_applied_from_the_same_file(self):
        code, result = self.run_apply()
        self.assertEqual(code, 0)
        self.assertEqual(result["outcome"], "applied")
        self.assertEqual(result["counts"], {"add": 1, "change": 0, "remove": 0})
        self.assertEqual(self.commands, ["init", "validate", "plan", "show", "apply"])
        runner = self.root / "runner"
        self.assertFalse(any(runner.glob("tofu-apply-apps-devstg-*")))
        self.assertFalse((runner / "aws").exists())
        self.assertFalse((self.root / "workspace/config/common.tfvars").exists())
        self.assertIn("AWS_SESSION_TOKEN=\n", (self.root / "github-env").read_text())

    def test_a_marker_keeps_the_lock_if_the_job_dies_mid_apply(self):
        self.run_apply()
        self.assertEqual(self.marker_before_apply["failure"]["stage"], "apply")

    def test_the_digest_key_never_reaches_tofu(self):
        self.run_apply()
        for env in self.envs:
            self.assertNotIn("PLAN_DIGEST_KEY", env)
            self.assertNotIn(KEY, env.values())

    def test_a_different_plan_is_not_applied(self):
        code, result = self.run_apply(reviewed="hmac-sha256:v1:" + "0" * 64)
        self.assertEqual(code, 1)
        self.assertEqual(result["outcome"], "rejected")
        self.assertIn("changed since it was reviewed", result["reasons"][0])
        self.assertNotIn("apply", self.commands)

    def test_destroy_needs_the_flag(self):
        plan = {"resource_changes": [{"address": "a.b", "change": {"actions": ["delete", "create"]}}]}
        code, result = self.run_apply(plan=plan)
        self.assertEqual((code, result["outcome"]), (1, "rejected"))
        self.assertNotIn("apply", self.commands)

    def test_destroy_with_the_flag_is_applied(self):
        plan = {"resource_changes": [{"address": "a.b", "change": {"actions": ["delete"]}}]}
        code, result = self.run_apply(plan=plan, extra={"ALLOW_DESTROY": "true"})
        self.assertEqual((code, result["outcome"]), (0, "applied"))

    def test_no_changes_applies_nothing(self):
        code, result = self.run_apply(plan={"resource_changes": []}, plan_exit=0)
        self.assertEqual((code, result["outcome"]), (0, "no-changes"))
        self.assertNotIn("apply", self.commands)

    def test_failed_apply_reports_the_stage(self):
        code, result = self.run_apply(apply_exit=1)
        self.assertEqual((code, result["outcome"]), (1, "failed"))
        self.assertEqual(result["failure"]["stage"], "apply")

    def test_layer_outside_the_allowlist_is_refused(self):
        self.env["APPLY_LAYERS"] = "other/layer"
        code, result = self.run_apply()
        self.assertEqual((code, result["outcome"]), (1, "failed"))
        self.assertEqual(self.commands, [])


class AuthorizeTests(ApplyWorkflowTestCase):
    def authorize(self, github, body="/tofu apply", results=None):
        results_dir = self.root / "plan"
        layer_dir = results_dir / "tofu-plan-layer-x"
        layer_dir.mkdir(parents=True)
        for index, value in enumerate(results if results is not None else [{
            "mode": "live", "status": "passed", "layer": LAYER,
            "plan_digest": "hmac-sha256:v1:" + "b" * 64, "summary": {"create": 1},
            "metadata": {"head_sha": HEAD, "repository": REPO},
        }]):
            (layer_dir / f"{index}").mkdir()
            (layer_dir / f"{index}" / "result.json").write_text(json.dumps(value))
        env = {**self.env, "COMMENT_BODY": body, "COMMENTER": "maintainer",
               "RESULTS_DIR": str(results_dir), "APPLY_ENABLED": "true",
               "TOFU_APPLY_ROLES": json.dumps({"apps-devstg": {
                   "role_arn": "arn:aws:iam::123456789012:role/GitHubActionsOpenTofuApply",
                   "account_id": "123456789012"}})}
        with patch.dict(os.environ, env, clear=True), patch.object(
            apply_workflow, "_github", return_value=github
        ), redirect_stdout(io.StringIO()):
            self.assertEqual(apply_workflow.run_authorize(), 0)
        return self.outputs(), self.state("decision.json")

    def test_allowed_apply_exposes_what_the_next_jobs_need(self):
        outputs, decision = self.authorize(FakeGitHub())
        self.assertEqual(outputs["allowed"], "true")
        self.assertEqual(outputs["layer"], LAYER)
        self.assertEqual(outputs["head_sha"], HEAD)
        self.assertEqual(decision["reasons"], [])

    def test_lock_held_by_another_pr_rejects(self):
        github = FakeGitHub(locks={"refs/tofu-locks/apps-devstg-global-cli-test-layer": lock_message(
            pr=9, layer=LAYER, head_sha=HEAD, run_id="1")})
        outputs, decision = self.authorize(github)
        self.assertEqual(outputs["allowed"], "false")
        self.assertEqual(decision["outcome"], "rejected")
        self.assertTrue(any("locked by #9" in reason for reason in decision["reasons"]))

    def test_unlock_without_a_lock_says_so(self):
        outputs, decision = self.authorize(FakeGitHub(), body="/tofu unlock")
        self.assertEqual(outputs["allowed"], "false")
        self.assertEqual(decision["outcome"], "not-locked")

    def test_unlock_of_own_lock_is_allowed(self):
        github = FakeGitHub(locks={"refs/tofu-locks/x": lock_message(pr=7, layer="x", head_sha=HEAD, run_id="1")})
        outputs, decision = self.authorize(github, body="/tofu unlock")
        self.assertEqual(outputs["allowed"], "true")
        self.assertEqual(decision["locks"], ["refs/tofu-locks/x"])


class ReportAndReleaseTests(ApplyWorkflowTestCase):
    def report(self, github, *, decision=None, result=None, extra=None):
        report_dir = self.root / "report"
        report_dir.mkdir()
        if decision is not None:
            (report_dir / "decision.json").write_text(json.dumps(decision))
        if result is not None:
            (report_dir / "result.json").write_text(json.dumps(result))
        env = {**self.env, "REPORT_DIR": str(report_dir), **(extra or {})}
        with patch.dict(os.environ, env, clear=True), patch.object(
            apply_workflow, "_github", return_value=github
        ), redirect_stdout(io.StringIO()):
            self.assertEqual(apply_workflow.run_report(), 0)

    def test_applied_sets_success_on_the_head(self):
        github = FakeGitHub()
        self.report(github, decision={"verb": "apply", "reasons": [], "head_sha": HEAD, "layer": LAYER},
                    result={"outcome": "applied", "layer": LAYER, "counts": {"add": 1}},
                    extra={"LOCK_CREATED": "true"})
        self.assertEqual(github.statuses[0][1]["state"], "success")
        self.assertIn("Applied", github.comments[0])
        self.assertEqual(github.deleted, [])

    def test_rejected_comments_without_a_status(self):
        github = FakeGitHub()
        self.report(github, decision={"verb": "apply", "reasons": ["no review"], "outcome": "rejected",
                                      "head_sha": HEAD})
        self.assertEqual(github.statuses, [])
        self.assertIn("- no review", github.comments[0])

    def test_unapplied_run_releases_only_the_lock_it_took(self):
        github = FakeGitHub()
        decision = {"verb": "apply", "reasons": [], "head_sha": HEAD, "layer": LAYER}
        self.report(github, decision=decision,
                    result={"outcome": "rejected", "layer": LAYER, "reasons": ["changed"]},
                    extra={"LOCK_CREATED": "true"})
        self.assertEqual(github.deleted, ["refs/tofu-locks/apps-devstg-global-cli-test-layer"])

    def test_failure_during_apply_keeps_the_lock(self):
        self.assertFalse(apply_workflow.should_release_lock(
            "failed", {"failure": {"stage": "apply"}}, True))
        self.assertTrue(apply_workflow.should_release_lock(
            "failed", {"failure": {"stage": "plan"}}, True))
        self.assertFalse(apply_workflow.should_release_lock("cancelled", {}, False))

    def test_without_a_result_the_lock_is_released_only_if_apply_never_ran(self):
        self.assertTrue(apply_workflow.should_release_lock(
            "failed", {}, True, apply_job_ran=False))
        self.assertFalse(apply_workflow.should_release_lock(
            "cancelled", {}, True, apply_job_ran=True))

    def test_apply_job_ran_reads_the_jobs_api_and_fails_closed(self):
        class Jobs(FakeGitHub):
            def __init__(self, jobs=None, error=False):
                super().__init__()
                self._jobs, self._error = jobs, error

            def run_jobs(self, run_id, attempt):
                if self._error:
                    raise RuntimeError("boom")
                return self._jobs

        with patch.dict(os.environ, self.env, clear=True):
            rejected = [{"name": "Apply · x", "steps": []}, {"name": "Lock · x", "steps": [{}]}]
            self.assertFalse(apply_workflow._apply_job_ran(Jobs(rejected)))
            self.assertTrue(apply_workflow._apply_job_ran(Jobs([{"name": "Apply · x", "steps": [{}]}])))
            self.assertTrue(apply_workflow._apply_job_ran(Jobs([])))
            self.assertTrue(apply_workflow._apply_job_ran(Jobs(error=True)))

    def test_rejected_approval_releases_a_fresh_lock(self):
        class Rejected(FakeGitHub):
            def run_jobs(self, run_id, attempt):
                return [{"name": "Apply · x", "steps": []}]

        github = Rejected()
        self.report(github, decision={"verb": "apply", "reasons": [], "head_sha": HEAD, "layer": LAYER},
                    extra={"APPLY_RESULT": "failure", "LOCK_CREATED": "true"})
        self.assertEqual(github.deleted, ["refs/tofu-locks/apps-devstg-global-cli-test-layer"])

    def test_rejected_approval_is_reported(self):
        github = FakeGitHub()
        self.report(github, decision={"verb": "apply", "reasons": [], "head_sha": HEAD, "layer": LAYER},
                    extra={"APPLY_RESULT": "failure"})
        self.assertIn("Apply failed", github.comments[0])
        self.assertEqual(github.statuses[0][1]["state"], "failure")

    def release(self, github, merged):
        env = {**self.env, "MERGED": merged}
        with patch.dict(os.environ, env, clear=True), patch.object(
            apply_workflow, "_github", return_value=github
        ), redirect_stdout(io.StringIO()):
            apply_workflow.run_release()

    def test_merge_releases_own_locks_only(self):
        github = FakeGitHub(locks={
            "refs/tofu-locks/a": lock_message(pr=7, layer="a", head_sha=HEAD, run_id="1"),
            "refs/tofu-locks/b": lock_message(pr=8, layer="b", head_sha=HEAD, run_id="1"),
        })
        self.release(github, "true")
        self.assertEqual(github.deleted, ["refs/tofu-locks/a"])

    def test_close_without_merge_keeps_the_lock_and_says_so(self):
        github = FakeGitHub(locks={"refs/tofu-locks/a": lock_message(pr=7, layer="a", head_sha=HEAD, run_id="1")})
        self.release(github, "false")
        self.assertEqual(github.deleted, [])
        self.assertIn("lock kept", github.comments[0])


class GitHubClientTests(unittest.TestCase):
    def test_existing_ref_is_not_an_error_and_other_errors_raise(self):
        calls = []

        def transport(method, path, body):
            calls.append((method, path))
            if path.endswith("/git/refs"):
                return 422, None
            return 500, None

        github = GitHub(REPO, transport)
        self.assertFalse(github.create_ref("refs/tofu-locks/x", "sha"))
        with self.assertRaises(RuntimeError):
            github.pull(1)

    def test_pagination_stops_on_a_short_page(self):
        pages = {1: [{"id": i} for i in range(100)], 2: [{"id": 100}]}

        def transport(method, path, body):
            page = int(path.rsplit("page=", 1)[1])
            return 200, pages.get(page, [])

        self.assertEqual(len(GitHub(REPO, transport).reviews(1)), 101)


if __name__ == "__main__":
    unittest.main()
