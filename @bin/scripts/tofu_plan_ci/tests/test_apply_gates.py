import json
import tempfile
import unittest
from pathlib import Path

from tofu_plan_ci import plan_report
from tofu_plan_ci.apply_gates import (
    Command,
    comment_body,
    decide_apply,
    lock_message,
    lock_ref,
    parse_command,
    parse_lock,
    plan_status,
    pr_status,
    recheck_reasons,
    review_reasons,
    select_plan_run,
    touched_apply_layers,
)

HEAD = "a" * 40
REPO = "example/infrastructure"
DIGEST = "hmac-sha256:v1:" + "b" * 64
LAYER = "apps-devstg/global/cli-test-layer"


def pr(**overrides):
    value = {
        "number": 7,
        "state": "open",
        "draft": False,
        "user": {"login": "author", "type": "User"},
        "head": {"sha": HEAD, "repo": {"full_name": REPO}},
        "base": {"ref": "master"},
    }
    value.update(overrides)
    return value


def approval(login="reviewer", state="APPROVED", commit=HEAD):
    return {"user": {"login": login}, "state": state, "commit_id": commit}


def result(**overrides):
    value = {
        "mode": "live",
        "status": "passed",
        "layer": LAYER,
        "plan_digest": DIGEST,
        "summary": {"create": 1, "update": 0, "delete": 0, "replace": 0, "no-op": 0},
        "metadata": {"head_sha": HEAD, "repository": REPO},
    }
    value.update(overrides)
    return value


class CommandTests(unittest.TestCase):
    def test_apply_unlock_and_flags(self):
        self.assertEqual(parse_command("/tofu apply"), Command("apply"))
        self.assertEqual(parse_command("\n  /tofu apply --allow-destroy  \nthanks"),
                         Command("apply", allow_destroy=True))
        self.assertEqual(parse_command("/tofu unlock"), Command("unlock"))

    def test_other_verbs_and_text_are_left_alone(self):
        for body in ("/tofu plan", "/tf-plan", "please /tofu apply", "/tofu", "/tofu apply now", ""):
            self.assertIsNone(parse_command(body), body)

    def test_unknown_or_misplaced_flags_are_errors(self):
        self.assertIn("unsupported flag --force", parse_command("/tofu apply --force").error)
        self.assertIsNotNone(parse_command("/tofu unlock --allow-destroy").error)
        self.assertIsNotNone(parse_command("/tofu apply --allow-destroy --allow-destroy").error)


class ReviewTests(unittest.TestCase):
    def test_needs_an_approval_on_head_by_someone_else(self):
        self.assertEqual(review_reasons(pr(), [approval()], HEAD), [])
        self.assertTrue(review_reasons(pr(), [approval(commit="c" * 40)], HEAD))
        self.assertTrue(review_reasons(pr(), [approval(login="author")], HEAD))
        self.assertTrue(review_reasons(pr(), [], HEAD))

    def test_latest_decisive_review_wins(self):
        dismissed = [approval(), approval(state="DISMISSED")]
        self.assertTrue(review_reasons(pr(), dismissed, HEAD))
        commented_after = [approval(), approval(state="COMMENTED")]
        self.assertEqual(review_reasons(pr(), commented_after, HEAD), [])
        blocked = [approval(), approval(login="other", state="CHANGES_REQUESTED")]
        self.assertIn("changes requested by other", review_reasons(pr(), blocked, HEAD))


class DecideApplyTests(unittest.TestCase):
    def decide(self, **overrides):
        args = dict(
            command=Command("apply"),
            repository=REPO,
            pr=pr(),
            permission="write",
            reviews=[approval()],
            compare={"behind_by": 0},
            plan_run={"id": 1, "status": "completed", "conclusion": "success"},
            results=[result()],
            lock=None,
            apply_layers=[LAYER],
            role_accounts=["apps-devstg"],
            enabled=True,
        )
        args.update(overrides)
        return decide_apply(**args)

    def test_happy_path(self):
        decision = self.decide()
        self.assertTrue(decision.allowed, decision.reasons)
        self.assertEqual((decision.layer, decision.digest), (LAYER, DIGEST))

    def test_each_gate_rejects(self):
        cases = {
            "disabled": dict(enabled=False),
            "write access": dict(permission="read"),
            "draft": dict(pr=pr(draft=True)),
            "fork": dict(pr=pr(head={"sha": HEAD, "repo": {"full_name": "fork/x"}})),
            "approving review": dict(reviews=[]),
            "behind": dict(compare={"behind_by": 2}),
            "not finished": dict(plan_run={"status": "in_progress"}),
            "did not succeed": dict(plan_run={"status": "completed", "conclusion": "failure"}),
            "exactly one": dict(results=[]),
            "no plan digest": dict(results=[result(plan_digest=None)]),
            "does not belong": dict(results=[result(metadata={"head_sha": "c" * 40, "repository": REPO})]),
            "TOFU_APPLY_LAYERS": dict(apply_layers=[]),
            "TOFU_APPLY_ROLES": dict(role_accounts=[]),
            "locked by #9": dict(lock={"pr": 9}),
            "--allow-destroy": dict(results=[result(summary={"delete": 1, "replace": 1})]),
        }
        for expected, override in cases.items():
            with self.subTest(expected):
                decision = self.decide(**override)
                self.assertFalse(decision.allowed)
                self.assertTrue(any(expected in reason for reason in decision.reasons), decision.reasons)

    def test_own_lock_and_allowed_destroy_pass(self):
        decision = self.decide(
            lock={"pr": 7},
            command=Command("apply", allow_destroy=True),
            results=[result(summary={"delete": 1})],
        )
        self.assertTrue(decision.allowed, decision.reasons)
        self.assertEqual(decision.destructive, 1)

    def test_a_command_error_is_the_only_reason(self):
        decision = self.decide(command=Command("apply", error="bad flag"), permission="read")
        self.assertEqual(decision.reasons, ["bad flag"])


class RecheckTests(unittest.TestCase):
    def test_new_head_stops_before_reviews(self):
        moved = pr(head={"sha": "d" * 40, "repo": {"full_name": REPO}})
        reasons = recheck_reasons(pr=moved, repository=REPO, reviews=[], compare={}, head_sha=HEAD)
        self.assertEqual(len(reasons), 1)
        self.assertIn("new commits", reasons[0])

    def test_master_moved(self):
        reasons = recheck_reasons(pr=pr(), repository=REPO, reviews=[approval()],
                                  compare={"behind_by": 1}, head_sha=HEAD)
        self.assertIn("behind", reasons[0])


class PlanRunAndLockTests(unittest.TestCase):
    def test_latest_pull_request_run_on_the_commit(self):
        runs = [
            {"id": 1, "head_sha": HEAD, "event": "pull_request", "run_number": 1},
            {"id": 2, "head_sha": HEAD, "event": "workflow_dispatch", "run_number": 3},
            {"id": 3, "head_sha": HEAD, "event": "pull_request", "run_number": 2},
            {"id": 4, "head_sha": "c" * 40, "event": "pull_request", "run_number": 9},
        ]
        self.assertEqual(select_plan_run(runs, HEAD)["id"], 3)
        self.assertIsNone(select_plan_run([], HEAD))

    def test_lock_message_round_trip(self):
        message = lock_message(pr=7, layer=LAYER, head_sha=HEAD, run_id="5")
        self.assertEqual(parse_lock(message)["pr"], 7)
        self.assertIsNone(parse_lock("some other tag"))
        self.assertIsNone(parse_lock("tofu-apply lock\n\n{\"pr\": \"7\"}"))
        self.assertEqual(lock_ref("x"), "refs/tofu-locks/x")


class PlanStatusTests(unittest.TestCase):
    def test_states(self):
        self.assertEqual(plan_status(results=[], apply_layers=[LAYER])[0], "success")
        self.assertIsNone(plan_status(results=[result(status="failed")], apply_layers=[LAYER]))
        no_changes = result(summary={"create": 0, "update": 0, "delete": 0, "replace": 0, "no-op": 3})
        self.assertIn("no changes", plan_status(results=[no_changes], apply_layers=[LAYER])[1])
        self.assertEqual(plan_status(results=[result()], apply_layers=[LAYER])[0], "pending")
        self.assertIn("manually", plan_status(results=[result()], apply_layers=[])[1])



class PrStatusTests(unittest.TestCase):
    RUN = {"id": 1, "conclusion": "success"}
    DISCOVERY = {"layers": [LAYER], "live_eligible": True}
    TOUCHED = [f"{LAYER}/main.tf"]

    def status(self, paths=TOUCHED, **overrides):
        args = dict(paths=paths, apply_layers=[LAYER], head_sha=HEAD, plan_run=self.RUN,
                    discovery=self.DISCOVERY, plan_live=True, results=[])
        args.update(overrides)
        return pr_status(**args)[0]

    def test_touched_layers(self):
        self.assertEqual(touched_apply_layers([f"{LAYER}/main.tf"], [LAYER]), [LAYER])
        self.assertEqual(touched_apply_layers(["config/common.tfvars"], [LAYER]), [LAYER])
        self.assertEqual(touched_apply_layers(["apps-devstg/config/backend.tfvars"], [LAYER]), [LAYER])
        for path in (f"{LAYER}-other/main.tf", "apps-prd/config/backend.tfvars", "README.md"):
            self.assertEqual(touched_apply_layers([path], [LAYER]), [], path)

    def test_before_the_plan(self):
        self.assertEqual(self.status(["docs/x.md"], plan_run=None), "success")
        self.assertEqual(self.status(plan_run=None), "pending")

    def test_live_plan_evidence_decides(self):
        no_changes = result(summary={"create": 0, "no-op": 1})
        self.assertEqual(self.status(results=[no_changes]), "success")
        self.assertEqual(self.status(results=[result()]), "pending")
        self.assertEqual(self.status(results=[result(status="failed")]), "pending")

    def test_missing_evidence_stays_pending(self):
        validation_only = result(mode="static", plan_digest=None)
        other_commit = result(summary={"create": 0}, metadata={"head_sha": "c" * 40, "repository": REPO})
        for name, overrides in {
            "no results": dict(results=[]),
            "no discovery": dict(discovery=None, results=[result(summary={"create": 0})]),
            "validation when live was due": dict(results=[validation_only]),
            "another commit": dict(results=[other_commit]),
            "failed run": dict(plan_run={"conclusion": "failure"}),
        }.items():
            with self.subTest(name):
                self.assertEqual(self.status(**overrides), "pending")

    def test_positive_evidence_of_no_live_plan(self):
        validation_only = result(mode="static", plan_digest=None)
        self.assertEqual(self.status(plan_live=False, results=[validation_only]), "success")
        blockers = {"layers": [LAYER], "live_eligible": False}
        self.assertEqual(self.status(discovery=blockers, results=[validation_only]), "success")
        self.assertEqual(self.status(discovery={"layers": [], "live_eligible": True}), "success")
        self.assertEqual(self.status(plan_run={"conclusion": "skipped"}, discovery=None), "success")

    def test_a_real_validation_report_is_positive_evidence(self):
        # Built by the same code the plan workflow runs, so the mode names cannot drift.
        with tempfile.TemporaryDirectory() as directory:
            plan_report.main(["static", "--layer", LAYER, "--init-exit", "0", "--validate-exit", "0",
                              "--out-dir", directory, "--repository", REPO, "--head-sha", HEAD])
            static = json.loads((Path(directory) / "result.json").read_text())
        blockers = {"layers": [LAYER], "live_eligible": False}
        self.assertEqual(self.status(discovery=blockers, results=[static]), "success")
        self.assertEqual(self.status(discovery=blockers, results=[]), "pending")

    def test_changed_plan_tooling_is_decided_without_the_evidence(self):
        for tooling in ("@bin/scripts/tofu_plan_ci/workflow.py", ".github/workflows/tofu-plan.yml"):
            paths = [f"{LAYER}/main.tf", tooling]
            self.assertEqual(self.status(paths, plan_run=None), "success")
            self.assertEqual(self.status(paths, results=[result()]), "success")


class CommentTests(unittest.TestCase):
    def test_comment_lists_reasons_and_link_only(self):
        body = comment_body(verb="apply", outcome="rejected", layer=LAYER,
                            run_url="https://example/run", reasons=["a reason"])
        self.assertIn("⛔ Not applied", body)
        self.assertIn("- a reason", body)
        self.assertIn("[Run](https://example/run)", body)

    def test_applied_comment_asks_to_merge(self):
        body = comment_body(verb="apply", outcome="applied", layer=LAYER, run_url="u",
                            counts={"add": 3, "change": 0, "remove": 0})
        self.assertIn("3 added", body)
        self.assertIn("Merge it now", body)


if __name__ == "__main__":
    unittest.main()
