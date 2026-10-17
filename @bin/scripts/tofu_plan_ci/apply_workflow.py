"""Run the steps of the apply-before-merge workflow (`/tofu apply` on a PR).

Every step here runs from the trusted default-branch revision. Only the apply
step executes the PR's OpenTofu code, and it does so with the apply role,
behind the `tofu-apply` environment approval.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
from pathlib import Path
from typing import Sequence

from . import apply_gates, plan_digest, plan_identity, workflow
from .github_api import GitHub, urllib_transport
from .workflow import _append, _output, _required_env, layer_slug

PLAN_WORKFLOW = "tofu-plan.yml"


def _github() -> GitHub:
    return GitHub(_required_env("GITHUB_REPOSITORY"), urllib_transport(_required_env("GH_TOKEN")))


def _run_url() -> str:
    server = os.environ.get("GITHUB_SERVER_URL", "https://github.com")
    return f"{server}/{os.environ.get('GITHUB_REPOSITORY', '')}/actions/runs/{os.environ.get('GITHUB_RUN_ID', '')}"


def _state_dir() -> Path:
    directory = Path(_required_env("RUNNER_TEMP")) / "tofu-apply"
    directory.mkdir(parents=True, exist_ok=True)
    return directory


def _write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _apply_layers() -> list[str]:
    return [layer.strip() for layer in re.split(r"[,\n]", os.environ.get("APPLY_LAYERS", ""))
            if layer.strip()]


def _role_accounts() -> list[str]:
    value = os.environ.get("TOFU_APPLY_ROLES", "")
    if not value:
        return []
    try:
        return list(plan_identity.parse_roles(value, "TOFU_APPLY_ROLES"))
    except ValueError as error:
        print(f"::warning::{error}")
        return []


def read_locks(github: GitHub, slug: str | None = None) -> dict[str, dict]:
    """Map each lock ref (optionally only the one for slug) to its parsed owner."""

    prefix = apply_gates.LOCK_NAMESPACE + "/" + (slug or "")
    locks = {}
    for ref in github.matching_refs(prefix):
        name = ref.get("ref", "")
        if slug and name != apply_gates.lock_ref(slug):
            continue
        target = ref.get("object") or {}
        owner = None
        if target.get("type") == "tag":
            owner = apply_gates.parse_lock(github.tag(target["sha"]).get("message", ""))
        # An unreadable lock still blocks: it is somebody's, we just cannot tell whose.
        locks[name] = owner or {"pr": None}
    return locks


def run_command() -> int:
    """Parse the comment, acknowledge it, and find the plan run to download."""

    command = apply_gates.parse_command(os.environ.get("COMMENT_BODY", ""))
    if command is None:
        _output("verb", "none")
        return 0
    github = _github()
    github.react(int(_required_env("COMMENT_ID")), "eyes")
    _output("verb", command.verb)
    if command.verb != "apply" or command.error:
        return 0
    pr = github.pull(int(_required_env("PR_NUMBER")))
    head_sha = pr["head"]["sha"]
    run = apply_gates.select_plan_run(github.workflow_runs(PLAN_WORKFLOW, head_sha), head_sha)
    _output("plan_run_id", str(run["id"]) if run and not apply_gates.plan_run_reasons(run) else "")
    return 0


def _load_results(directory: Path) -> list[dict]:
    if not directory.is_dir():
        return []
    return [json.loads(path.read_text(encoding="utf-8")) for path in sorted(directory.rglob("result.json"))]


def run_authorize() -> int:
    command = apply_gates.parse_command(os.environ.get("COMMENT_BODY", ""))
    if command is None:
        raise ValueError("authorize ran without a /tofu command")
    github = _github()
    repository = _required_env("GITHUB_REPOSITORY")
    number = int(_required_env("PR_NUMBER"))
    pr = github.pull(number)
    head_sha = pr["head"]["sha"]
    permission = github.permission(_required_env("COMMENTER"))

    if command.verb == "unlock":
        reasons = list(filter(None, [command.error]))
        if permission not in apply_gates.WRITE_PERMISSIONS:
            reasons.append("the commenter does not have write access")
        owned = [ref for ref, owner in read_locks(github).items() if owner.get("pr") == number]
        decision = apply_gates.Decision("unlock", reasons)
        payload = {"verb": "unlock", "reasons": reasons, "locks": owned, "pr": number}
        _output("allowed", str(decision.allowed and bool(owned)).lower())
        if decision.allowed and not owned:
            payload["outcome"] = "not-locked"
    else:
        run = apply_gates.select_plan_run(github.workflow_runs(PLAN_WORKFLOW, head_sha), head_sha)
        layer_hint = ""
        results = _load_results(Path(os.environ.get("RESULTS_DIR", "")))
        live = [result for result in results if result.get("mode") == "live"]
        if len(live) == 1:
            layer_hint = str(live[0].get("layer", ""))
        locks = read_locks(github, layer_slug(layer_hint)) if layer_hint else {}
        decision = apply_gates.decide_apply(
            command=command,
            repository=repository,
            pr=pr,
            permission=permission,
            reviews=github.reviews(number),
            compare=github.compare(pr["base"]["ref"], head_sha),
            plan_run=run,
            results=results,
            lock=next(iter(locks.values()), None),
            apply_layers=_apply_layers(),
            role_accounts=_role_accounts(),
            enabled=os.environ.get("APPLY_ENABLED") == "true",
        )
        payload = {
            "verb": "apply",
            "reasons": decision.reasons,
            "pr": number,
            "head_sha": head_sha,
            "layer": decision.layer,
            "digest": decision.digest,
            "allow_destroy": command.allow_destroy,
            "destructive": decision.destructive,
            "plan_run_id": run.get("id") if run else None,
        }
        _output("allowed", str(decision.allowed).lower())
        if decision.allowed:
            _output("layer", decision.layer)
            _output("slug", layer_slug(decision.layer))
            _output("digest", decision.digest)
            _output("head_sha", head_sha)
            _output("allow_destroy", str(command.allow_destroy).lower())
    if decision.reasons:
        payload["outcome"] = "rejected"
    _write_json(_state_dir() / "decision.json", payload)
    return 0


def run_lock() -> int:
    """Take the layer's lock for this PR, or confirm this PR already holds it."""

    github = _github()
    number = int(_required_env("PR_NUMBER"))
    layer = _required_env("LAYER")
    head_sha = _required_env("HEAD_SHA")
    slug = layer_slug(layer)
    ref = apply_gates.lock_ref(slug)
    message = apply_gates.lock_message(pr=number, layer=layer, head_sha=head_sha,
                                       run_id=os.environ.get("GITHUB_RUN_ID", ""))
    tag_sha = github.create_tag(tag=f"tofu-lock-{slug}", message=message, commit=head_sha)
    if github.create_ref(ref, tag_sha):
        print(f"Locked {layer} for #{number}")
        _output("created", "true")
        return 0
    owner = read_locks(github, slug).get(ref, {"pr": None})
    if owner.get("pr") == number:
        print(f"#{number} already holds the lock on {layer}")
        _output("created", "false")
        return 0
    print(f"::error::{layer} is locked by #{owner.get('pr')}")
    return 1


def _reject(reasons: Sequence[str], layer: str) -> int:
    _write_json(_state_dir() / "result.json",
                {"outcome": "rejected", "layer": layer, "reasons": list(reasons)})
    for reason in reasons:
        print(f"::error::{reason}")
    return 1


def run_recheck() -> int:
    """Re-check what may have changed while the job waited for approval."""

    github = _github()
    number = int(_required_env("PR_NUMBER"))
    pr = github.pull(number)
    head_sha = _required_env("HEAD_SHA")
    reasons = apply_gates.recheck_reasons(
        pr=pr,
        repository=_required_env("GITHUB_REPOSITORY"),
        reviews=github.reviews(number),
        compare=github.compare(pr["base"]["ref"], head_sha),
        head_sha=head_sha,
    )
    if os.environ.get("APPLY_ENABLED") != "true":
        reasons.append("applies were disabled while the job waited (`TOFU_APPLY_LIVE`)")
    return _reject(reasons, _required_env("LAYER")) if reasons else 0


def run_credentials(layer: str) -> int:
    try:
        if layer not in _apply_layers():
            raise ValueError(f"layer is not in the APPLY_LAYERS allowlist: {layer}")
        workspace = Path(os.environ.get("CANDIDATE_ROOT") or _required_env("GITHUB_WORKSPACE")).resolve()
        resolved = plan_identity.resolve(
            workspace, layer, _required_env("TOFU_APPLY_ROLES"),
            roles_name="TOFU_APPLY_ROLES", write_state=True,
        )
    except (OSError, ValueError) as error:
        print(f"::error::{error}")
        return 1
    print(f"::add-mask::{resolved['account_id']}")
    for name, value in resolved.items():
        _output(name, value)
    return 0


def change_summary(log: Path) -> dict | None:
    """The `change_summary` counts from `tofu apply -json`, and nothing else."""

    if not log.is_file():
        return None
    for line in log.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            message = json.loads(line)
        except json.JSONDecodeError:
            continue
        changes = message.get("changes") if message.get("type") == "change_summary" else None
        if isinstance(changes, dict) and changes.get("operation") == "apply":
            return {name: int(changes.get(name, 0)) for name in ("add", "change", "remove")}
    return None


def destructive_changes(plan: dict) -> int:
    return sum(
        1 for item in plan.get("resource_changes") or []
        if "delete" in ((item.get("change") or {}).get("actions") or [])
    )


def run_apply(layer: str) -> int:
    """Re-plan, prove it is the reviewed plan, and apply that same plan file."""

    slug = layer_slug(layer)
    workspace = Path(os.environ.get("CANDIDATE_ROOT") or _required_env("GITHUB_WORKSPACE")).resolve()
    runner_temp = Path(_required_env("RUNNER_TEMP"))
    layer_dir = workspace / layer
    common_tfvars = workspace / "config" / "common.tfvars"
    plan_file = runner_temp / f"tofu-apply-{slug}"
    plan_json = runner_temp / f"tofu-apply-{slug}.json"
    logs = [runner_temp / name for name in (
        "tofu-apply-init.log", "tofu-apply-validate.log", "tofu-apply-plan.jsonl",
        "tofu-apply-show.log", "tofu-apply.jsonl")]
    # Popped, not read: the tofu subprocesses get a copy of this environment.
    digest_key = os.environ.pop("PLAN_DIGEST_KEY", "")
    result: dict = {"outcome": "failed", "layer": layer, "reasons": []}
    stage = "setup"

    try:
        if layer not in _apply_layers():
            raise ValueError(f"layer is not in the APPLY_LAYERS allowlist: {layer}")
        reviewed = _required_env("REVIEWED_DIGEST")
        if not digest_key:
            raise ValueError("PLAN_DIGEST_KEY is not set on the tofu-apply environment")
        common = _required_env("COMMON_TFVARS")
        common_tfvars.write_text(common.rstrip("\n") + "\n", encoding="utf-8")
        common_tfvars.chmod(0o600)
        account = layer.split("/", 1)[0]
        backend_config = workspace / account / "config" / "backend.tfvars"
        account_config = workspace / account / "config" / "account.tfvars"
        process_env = workflow._write_aws_profile(
            runner_temp / "aws",
            profile=workflow.read_backend_profile(backend_config),
            region=os.environ.get("AWS_REGION", "us-east-1"),
        )
        var_files = [f"-var-file={path}" for path in (common_tfvars, account_config, backend_config)]

        stage = "init"
        if workflow.run_logged(
            ["tofu", "init", "-reconfigure", "-input=false", "-lockfile=readonly", "-no-color",
             f"-backend-config={backend_config}"],
            stdout_path=logs[0], env=process_env, cwd=layer_dir,
        ) != 0:
            raise RuntimeError(stage)
        stage = "validate"
        if workflow.run_logged(["tofu", "validate", "-no-color"], stdout_path=logs[1],
                               env=process_env, cwd=layer_dir) != 0:
            raise RuntimeError(stage)
        stage = "plan"
        plan_exit = workflow.run_logged(
            ["tofu", "plan", "-input=false", "-lock-timeout=5m", "-detailed-exitcode", "-json",
             f"-out={plan_file}", *var_files],
            stdout_path=logs[2], env=process_env, cwd=layer_dir,
        )
        if plan_exit not in (0, 2) or workflow.run_logged(
            ["tofu", "show", "-json", str(plan_file)], stdout_path=plan_json,
            stderr_path=logs[3], env=process_env, cwd=layer_dir,
        ) != 0:
            raise RuntimeError(stage)
        plan = json.loads(plan_json.read_text(encoding="utf-8"))

        stage = "compare"
        if not plan_digest.digests_match(plan_digest.plan_digest(plan, digest_key), reviewed):
            result.update(outcome="rejected", reasons=[
                "the plan changed since it was reviewed (a new commit, drift, or a changed "
                "value); push or re-run the plan, review it, and apply again"])
            return _finish(result)
        destroyed = destructive_changes(plan)
        if destroyed and os.environ.get("ALLOW_DESTROY") != "true":
            result.update(outcome="rejected", reasons=[
                f"the plan deletes or replaces {destroyed} resource(s); "
                "comment `/tofu apply --allow-destroy` to apply it"])
            return _finish(result)
        if plan_exit == 0:
            result.update(outcome="no-changes")
            return _finish(result)

        stage = "apply"
        # From here on the infrastructure may change. If the job dies mid-apply,
        # this marker (uploaded by an always() step) keeps the lock in place.
        _write_json(_state_dir() / "result.json", {**result, "failure": {"stage": "apply"}})
        apply_exit = workflow.run_logged(
            ["tofu", "apply", "-input=false", "-lock-timeout=5m", "-json", str(plan_file)],
            stdout_path=logs[4], env=process_env, cwd=layer_dir,
        )
        result["counts"] = change_summary(logs[4])
        if apply_exit != 0:
            raise RuntimeError(stage)
        result["outcome"] = "applied"
        return _finish(result)
    except RuntimeError:
        result["failure"] = {
            "stage": stage,
            "denied_action": workflow.denied_action_from_logs(logs),
            "diagnostic": workflow.diagnostic_summary_from_logs(logs[2:3] + logs[4:]),
            "location": workflow.diagnostic_location_from_logs(logs[2:3] + logs[4:]),
        }
        return _finish(result)
    except (OSError, ValueError) as error:
        print(f"::error::{error}")
        result["failure"] = {"stage": stage}
        return _finish(result)
    finally:
        for path in (common_tfvars, plan_file, plan_json, *logs):
            path.unlink(missing_ok=True)
        shutil.rmtree(runner_temp / "aws", ignore_errors=True)
        _append(os.environ.get("GITHUB_ENV"),
                "AWS_ACCESS_KEY_ID=\nAWS_SECRET_ACCESS_KEY=\nAWS_SESSION_TOKEN=\n")


def _finish(result: dict) -> int:
    _write_json(_state_dir() / "result.json", result)
    _output("outcome", result["outcome"])
    summary = f"## OpenTofu apply: `{result['layer']}`\n\n- Outcome: **{result['outcome']}**\n"
    if result.get("counts"):
        summary += f"- Changes: {json.dumps(result['counts'], sort_keys=True)}\n"
    for reason in result.get("reasons") or []:
        summary += f"- {reason}\n"
    if failure := result.get("failure"):
        summary += "".join(f"- Failure {name}: `{value}`\n" for name, value in failure.items() if value)
    _append(os.environ.get("GITHUB_STEP_SUMMARY"), summary)
    return 0 if result["outcome"] in ("applied", "no-changes") else 1


def run_report() -> int:
    """Reply once on the PR and set the `OpenTofu Apply` status on the head commit."""

    state = Path(os.environ.get("REPORT_DIR", ""))
    decision = json.loads((state / "decision.json").read_text(encoding="utf-8")) \
        if (state / "decision.json").is_file() else {}
    result = json.loads((state / "result.json").read_text(encoding="utf-8")) \
        if (state / "result.json").is_file() else {}
    verb = decision.get("verb") or os.environ.get("VERB", "apply")
    layer = result.get("layer") or decision.get("layer", "")
    reasons = list(decision.get("reasons") or [])

    if decision.get("outcome"):
        outcome = decision["outcome"]
    elif verb == "unlock":
        outcome = "unlocked" if os.environ.get("UNLOCK_RESULT") == "success" else "failed"
        if outcome == "failed":
            reasons.append("the unlock job did not complete (approval rejected or cancelled)")
    elif result:
        outcome = result["outcome"]
        reasons += result.get("reasons") or []
        if failure := result.get("failure"):
            reasons += [f"failed at `{failure.get('stage')}`"] + [
                f"{name}: `{value}`" for name, value in failure.items()
                if value and name != "stage"]
    elif not decision:
        outcome = "failed"
        reasons.append("the request could not be evaluated; see the run")
    elif os.environ.get("LOCK_RESULT") == "failure":
        outcome = "rejected"
        reasons.append(f"`{layer}` is locked by another pull request")
    else:
        apply_result = os.environ.get("APPLY_RESULT", "")
        outcome = "cancelled" if apply_result in ("cancelled", "skipped") else "failed"
        reasons.append(
            f"the apply job ended as `{apply_result or 'unknown'}` before reporting "
            "(approval rejected or cancelled)")

    github = _github()
    created = os.environ.get("LOCK_CREATED") == "true"
    if should_release_lock(outcome, result, created,
                           apply_job_ran=bool(created and not result) and _apply_job_ran(github)):
        github.delete_ref(apply_gates.lock_ref(layer_slug(layer)))
        reasons.append("nothing was applied, so the lock this run took was released")
    run_url = _run_url()
    github.comment(int(_required_env("PR_NUMBER")), apply_gates.comment_body(
        verb=verb, outcome=outcome, layer=layer, run_url=run_url, reasons=reasons,
        counts=result.get("counts")))
    head_sha = decision.get("head_sha")
    states = {"applied": ("success", "Applied by CI"),
              "no-changes": ("success", "Nothing to apply"),
              "failed": ("failure", "Apply failed; see the run")}
    if verb == "apply" and head_sha and outcome in states:
        state_name, description = states[outcome]
        github.status(head_sha, state=state_name, context=apply_gates.STATUS_CONTEXT,
                      description=description, target_url=run_url)
    return 0


def _apply_job_ran(github: GitHub) -> bool:
    """Whether this run's apply job executed any step, judged from the jobs API.

    A rejected approval or a skipped job has no steps. When in doubt (the job is
    missing or the API fails), answer True so that the lock is kept.
    """

    try:
        jobs = github.run_jobs(_required_env("GITHUB_RUN_ID"),
                               os.environ.get("GITHUB_RUN_ATTEMPT", "1"))
    except (RuntimeError, ValueError):
        return True
    apply_jobs = [job for job in jobs if str(job.get("name", "")).startswith("Apply ")]
    return not apply_jobs or any(job.get("steps") for job in apply_jobs)


def should_release_lock(outcome: str, result: dict, created_by_this_run: bool,
                        *, apply_job_ran: bool = True) -> bool:
    """Release a lock this run took when it provably changed nothing.

    A lock that an earlier apply took is never released here: that PR has
    changed the infrastructure and still has to be merged or reverted. Without
    a result, the lock is released only if the apply job never ran a step;
    a job that died mid-apply leaves no result but may have changed things.
    """

    if not created_by_this_run or outcome == "applied":
        return False
    if not result:
        return not apply_job_ran
    return (result.get("failure") or {}).get("stage") != "apply"


def run_unlock() -> int:
    github = _github()
    number = int(_required_env("PR_NUMBER"))
    for ref, owner in read_locks(github).items():
        if owner.get("pr") == number:
            github.delete_ref(ref)
            print(f"Released {ref}")
    return 0


def run_release() -> int:
    """On PR close: release its locks if merged, keep them (and say so) if not."""

    github = _github()
    number = int(_required_env("PR_NUMBER"))
    owned = [ref for ref, owner in read_locks(github).items() if owner.get("pr") == number]
    if not owned:
        return 0
    if os.environ.get("MERGED") == "true":
        for ref in owned:
            github.delete_ref(ref)
            print(f"Released {ref}")
        return 0
    layers = ", ".join(f"`{ref.rsplit('/', 1)[-1]}`" for ref in owned)
    github.comment(number, (
        f"**🔒 Closed without merging, lock kept** · {layers}\n\n"
        "This PR applied changes that `master` does not have. Revert them here and "
        "`/tofu apply`, then `/tofu unlock`; reopen the PR to do so."))
    return 0


def run_plan_status() -> int:
    """Post the `OpenTofu Apply` status from the plan workflow's report job."""

    results = _load_results(Path(_required_env("RESULTS_DIR")))
    status = apply_gates.plan_status(results=results, apply_layers=_apply_layers())
    if status is None:
        return 0
    state, description = status
    _github().status(_required_env("HEAD_SHA"), state=state,
                     context=apply_gates.STATUS_CONTEXT, description=description,
                     target_url=_run_url())
    return 0


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("command", "authorize", "lock", "recheck", "report", "unlock", "release",
                 "plan-status"):
        commands.add_parser(name)
    for name in ("credentials", "apply"):
        commands.add_parser(name).add_argument("--layer", default="")
    args = parser.parse_args(argv)
    handlers = {
        "command": run_command, "authorize": run_authorize, "lock": run_lock,
        "recheck": run_recheck, "report": run_report, "unlock": run_unlock,
        "release": run_release, "plan-status": run_plan_status,
    }
    if args.command in handlers:
        return handlers[args.command]()
    layer = args.layer or _required_env("LAYER")
    return run_credentials(layer) if args.command == "credentials" else run_apply(layer)


if __name__ == "__main__":
    raise SystemExit(main())
