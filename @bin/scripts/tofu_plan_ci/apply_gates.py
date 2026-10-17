"""Decisions for the apply-before-merge workflow, kept free of I/O.

Everything here takes plain data already fetched from GitHub or read from the
plan run's evidence, and returns a decision. The workflow steps in
apply_workflow do the fetching, so every rule can be tested on fixtures.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from typing import Any, Iterable, Sequence

from .discover import SELF_TEST_PATHS
from .plan_digest import DIGEST

STATUS_CONTEXT = "OpenTofu Apply"
LOCK_NAMESPACE = "tofu-locks"
LOCK_HEADER = "tofu-apply lock"
WRITE_PERMISSIONS = {"admin", "maintain", "write"}
COMMAND = re.compile(
    r"\A/tofu[ \t]+(?P<verb>[a-z-]+)(?P<flags>(?:[ \t]+--[a-z-]+)*)[ \t]*\Z"
)
SHA = re.compile(r"\A[0-9a-f]{40}\Z")
USAGE = "`/tofu apply`, `/tofu apply --allow-destroy`, or `/tofu unlock`"
# Files the plan run executes besides the PR's OpenTofu code. A PR that changes
# them ran its own plan workflow, so that run's evidence proves nothing.
PLAN_TOOLING = SELF_TEST_PATHS


@dataclass(frozen=True)
class Command:
    verb: str
    allow_destroy: bool = False
    error: str | None = None


def parse_command(body: str) -> Command | None:
    """Parse the first non-empty line of a PR comment.

    Only `apply` and `unlock` belong to this workflow. Any other `/tofu` verb
    (such as `/tofu plan`) is left alone, so other workflows can share the prefix.
    """

    line = next((line.strip() for line in body.splitlines() if line.strip()), "")
    match = COMMAND.match(line)
    if not match or match.group("verb") not in {"apply", "unlock"}:
        return None
    verb = match.group("verb")
    flags = match.group("flags").split()
    allowed = {"--allow-destroy"} if verb == "apply" else set()
    unknown = sorted(set(flags) - allowed)
    if unknown or len(flags) != len(set(flags)):
        return Command(verb, error=f"unsupported flag {' '.join(unknown) or 'repeated'}; use {USAGE}")
    return Command(verb, allow_destroy="--allow-destroy" in flags)


def lock_ref(slug: str) -> str:
    return f"refs/{LOCK_NAMESPACE}/{slug}"


def lock_message(*, pr: int, layer: str, head_sha: str, run_id: str) -> str:
    payload = {"pr": pr, "layer": layer, "head_sha": head_sha, "run_id": run_id}
    return f"{LOCK_HEADER}\n\n{json.dumps(payload, sort_keys=True)}\n"


def parse_lock(message: str) -> dict | None:
    header, _, body = message.partition("\n\n")
    if header.strip() != LOCK_HEADER:
        return None
    try:
        payload = json.loads(body)
    except json.JSONDecodeError:
        return None
    if not isinstance(payload, dict) or not isinstance(payload.get("pr"), int):
        return None
    return payload


def _latest_reviews(reviews: Iterable[dict]) -> dict[str, dict]:
    """Each reviewer's latest decisive review, as GitHub's merge box counts them."""

    latest: dict[str, dict] = {}
    for review in reviews:
        login = (review.get("user") or {}).get("login")
        state = review.get("state")
        if not login or state in {"COMMENTED", "PENDING"}:
            continue
        if state == "DISMISSED":
            latest.pop(login, None)
        else:
            latest[login] = review
    return latest


def review_reasons(pr: dict, reviews: Sequence[dict], head_sha: str) -> list[str]:
    author = (pr.get("user") or {}).get("login")
    latest = _latest_reviews(reviews)
    reasons = []
    if not any(
        login != author and review.get("state") == "APPROVED"
        and review.get("commit_id") == head_sha
        for login, review in latest.items()
    ):
        reasons.append("no approving review on the current head commit by someone other than the author")
    if blocking := sorted(
        login for login, review in latest.items() if review.get("state") == "CHANGES_REQUESTED"
    ):
        reasons.append(f"changes requested by {', '.join(blocking)}")
    return reasons


def pull_reasons(pr: dict, repository: str) -> list[str]:
    reasons = []
    if pr.get("state") != "open":
        reasons.append("the pull request is not open")
    if pr.get("draft"):
        reasons.append("the pull request is a draft")
    if ((pr.get("head") or {}).get("repo") or {}).get("full_name") != repository:
        reasons.append("the pull request comes from a fork")
    if (pr.get("user") or {}).get("type") != "User":
        reasons.append("the pull request was not opened by a user")
    return reasons


def freshness_reasons(compare: dict, base_ref: str) -> list[str]:
    behind = compare.get("behind_by")
    if behind != 0:
        return [f"the branch is {behind} commit(s) behind `{base_ref}`; update it, wait for the new plan, and apply again"]
    return []


def select_plan_run(runs: Sequence[dict], head_sha: str) -> dict | None:
    """The latest pull_request run of the plan workflow on this exact commit."""

    candidates = [
        run for run in runs
        if run.get("head_sha") == head_sha and run.get("event") == "pull_request"
    ]
    return max(candidates, key=lambda run: (run.get("run_number", 0), run.get("run_attempt", 0)),
               default=None)


def plan_run_reasons(run: dict | None) -> list[str]:
    if run is None:
        return ["no OpenTofu Plan run exists for the head commit"]
    if run.get("status") != "completed":
        return ["the OpenTofu Plan run for the head commit has not finished"]
    if run.get("conclusion") != "success":
        return ["the OpenTofu Plan run for the head commit did not succeed"]
    return []


def reviewed_plan(results: Sequence[dict], *, head_sha: str, repository: str
                  ) -> tuple[dict | None, list[str]]:
    """The one live, passed result that the apply must match."""

    live = [result for result in results if result.get("mode") == "live"]
    if len(live) != 1:
        return None, [f"the plan run has {len(live)} live layer results; exactly one is required"]
    result = live[0]
    metadata = result.get("metadata") or {}
    reasons = []
    if result.get("status") != "passed":
        reasons.append("the reviewed plan did not pass")
    if metadata.get("head_sha") != head_sha or metadata.get("repository") != repository:
        reasons.append("the reviewed plan's evidence does not belong to this commit")
    if not DIGEST.fullmatch(str(result.get("plan_digest") or "")):
        reasons.append("the reviewed plan has no plan digest")
    return (result if not reasons else None), reasons


def destructive_count(summary: dict | None) -> int:
    summary = summary or {}
    return int(summary.get("delete", 0)) + int(summary.get("replace", 0))


@dataclass
class Decision:
    verb: str
    reasons: list[str]
    layer: str = ""
    digest: str = ""
    destructive: int = 0

    @property
    def allowed(self) -> bool:
        return not self.reasons


def decide_apply(
    *,
    command: Command,
    repository: str,
    pr: dict,
    permission: str,
    reviews: Sequence[dict],
    compare: dict,
    plan_run: dict | None,
    results: Sequence[dict],
    lock: dict | None,
    apply_layers: Sequence[str],
    role_accounts: Iterable[str],
    enabled: bool,
) -> Decision:
    head_sha = (pr.get("head") or {}).get("sha", "")
    reasons: list[str] = []
    if command.error:
        return Decision("apply", [command.error])
    if not enabled:
        reasons.append("applies are disabled (`TOFU_APPLY_LIVE` is not `true`)")
    if permission not in WRITE_PERMISSIONS:
        reasons.append("the commenter does not have write access")
    reasons += pull_reasons(pr, repository)
    reasons += review_reasons(pr, reviews, head_sha)
    reasons += freshness_reasons(compare, (pr.get("base") or {}).get("ref", "master"))
    reasons += plan_run_reasons(plan_run)

    result, plan_reasons = reviewed_plan(results, head_sha=head_sha, repository=repository) \
        if not plan_run_reasons(plan_run) else (None, [])
    reasons += plan_reasons
    decision = Decision("apply", reasons)
    if result is None:
        return decision

    decision.layer = str(result.get("layer", ""))
    decision.digest = str(result["plan_digest"])
    decision.destructive = destructive_count(result.get("summary"))
    if decision.layer not in apply_layers:
        reasons.append(f"`{decision.layer}` is not in the `TOFU_APPLY_LAYERS` allowlist")
    if decision.layer.split("/", 1)[0] not in set(role_accounts):
        reasons.append(f"`TOFU_APPLY_ROLES` has no apply role for `{decision.layer.split('/', 1)[0]}`")
    if decision.destructive and not command.allow_destroy:
        reasons.append(
            f"the plan deletes or replaces {decision.destructive} resource(s); "
            "comment `/tofu apply --allow-destroy` to apply it"
        )
    if lock and lock.get("pr") != pr.get("number"):
        reasons.append(f"`{decision.layer}` is locked by #{lock.get('pr')} until it is merged or unlocked")
    return decision


def recheck_reasons(*, pr: dict, repository: str, reviews: Sequence[dict], compare: dict,
                    head_sha: str) -> list[str]:
    """Conditions that may change while the apply waits for approval."""

    reasons = pull_reasons(pr, repository)
    if (pr.get("head") or {}).get("sha") != head_sha:
        reasons.append("new commits were pushed after `/tofu apply`; wait for the new plan and apply again")
        return reasons
    reasons += review_reasons(pr, reviews, head_sha)
    reasons += freshness_reasons(compare, (pr.get("base") or {}).get("ref", "master"))
    return reasons


def plan_status(*, results: Sequence[dict], apply_layers: Sequence[str]) -> tuple[str, str] | None:
    """The `OpenTofu Apply` status that a finished plan's evidence supports.

    None means the plan itself failed.
    """

    live = [result for result in results if result.get("mode") == "live"]
    if not live:
        return "success", "No live plan for this commit: CI cannot apply it"
    if any(result.get("status") != "passed" for result in live):
        return None
    changing = [
        result for result in live
        if any(count for name, count in (result.get("summary") or {}).items() if name not in {"no-op", "read"})
    ]
    if not changing:
        return "success", "The plan has no changes: nothing to apply"
    if all(result.get("layer") in apply_layers for result in changing):
        return "pending", "Changes to apply: comment /tofu apply after review"
    return "success", "Layer not onboarded to CI apply: apply it manually"


def touched_apply_layers(paths: Iterable[str], apply_layers: Sequence[str]) -> list[str]:
    """The onboarded layers that a PR's changed files can affect.

    As in discovery: a file inside the layer, the project configuration, or
    the configuration of the layer's account.
    """

    touched = set()
    for path in paths:
        for layer in apply_layers:
            account = layer.split("/", 1)[0]
            if path.startswith((f"{layer}/", "config/", f"{account}/config/")):
                touched.add(layer)
    return sorted(touched)


def pr_status(*, paths: Sequence[str], apply_layers: Sequence[str], head_sha: str,
              plan_run: dict | None = None, results: Sequence[dict] = ()) -> tuple[str, str]:
    """The `OpenTofu Apply` status of a PR head, decided by the status workflow.

    `paths` comes from the API. Without `plan_run` (the PR event) this is the
    state until the plan finishes; with it, the plan's evidence decides. A PR
    that changes the plan tooling gets no live plan, so CI cannot apply it, and
    its run's evidence is never read: that run executed the PR's own workflow.
    """

    if not touched_apply_layers(paths, apply_layers):
        return "success", "No layer onboarded to CI apply changed"
    if any(path == PLAN_TOOLING[0] or path.startswith(PLAN_TOOLING[1]) for path in paths):
        return "success", "The plan tooling changed: no live plan, apply it manually"
    if plan_run is None:
        return "pending", "Waiting for the OpenTofu plan"
    if plan_run.get("conclusion") not in ("success", "skipped"):
        return "pending", "Waiting for a passing OpenTofu plan"
    own = [result for result in results
           if (result.get("metadata") or {}).get("head_sha") == head_sha]
    return (plan_status(results=own, apply_layers=apply_layers)
            or ("pending", "Waiting for a passing OpenTofu plan"))


def comment_body(*, verb: str, outcome: str, layer: str, run_url: str,
                 reasons: Sequence[str] = (), counts: dict | None = None) -> str:
    """The single reply to a command. It never contains plan content."""

    titles = {
        "applied": "✅ Applied",
        "no-changes": "✅ Nothing to apply",
        "rejected": "⛔ Not applied",
        "failed": "❌ Apply failed",
        "cancelled": "⚪ Apply cancelled",
        "unlocked": "🔓 Unlocked",
        "not-locked": "ℹ️ Nothing to unlock",
    }
    lines = [f"**{titles.get(outcome, outcome)}**" + (f" · `{layer}`" if layer else "")]
    if counts:
        lines.append(
            f"\n{counts.get('add', 0)} added, {counts.get('change', 0)} changed, "
            f"{counts.get('remove', 0)} destroyed."
        )
    if reasons:
        lines.append("")
        lines += [f"- {reason}" for reason in reasons]
    if outcome == "applied":
        lines.append("\nThe layer stays locked until this PR is merged. Merge it now so `master` matches the infrastructure.")
    if outcome == "failed":
        lines.append("\nFix forward (or revert) and `/tofu apply` again; do not merge until it is green.")
    lines.append(f"\n[Run]({run_url}) · `/tofu {verb}`")
    return "\n".join(lines)
