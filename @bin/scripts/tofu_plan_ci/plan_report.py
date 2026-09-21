"""Build a value-free review projection from an OpenTofu JSON plan."""

from __future__ import annotations

import argparse
import html
import json
import re
from pathlib import Path
from typing import Any, Sequence

from . import SCHEMA_VERSION

ACCOUNT_ID = re.compile(r"(?<!\d)\d{12}(?!\d)")
ARN = re.compile(r"arn:(?:aws|aws-us-gov|aws-cn):[^\s\"']+")
AWS_ACCESS_KEY = re.compile(r"(?<![A-Z0-9])(?:AKIA|ASIA)[A-Z0-9]{16}(?![A-Z0-9])")
GITHUB_TOKEN = re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})\b")
JWT = re.compile(r"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b")
EMAIL = re.compile(r"(?<![\w.+-])[\w.+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}(?![\w.-])")
INSTANCE_KEY = re.compile(r"\[[^\]]*\]")
AWS_ACTION = re.compile(r"[a-z0-9-]+:[A-Za-z][A-Za-z0-9]*\Z")
MISSING = object()

SECURITY_SENSITIVE_TYPES = (
    "aws_iam_",
    "aws_kms_",
    "aws_network_acl",
    "aws_route",
    "aws_s3_bucket_policy",
    "aws_secretsmanager_",
    "aws_security_group",
    "aws_ssm_parameter",
)


def redact_text(value: Any) -> str:
    text = " ".join(str(value).split())[:512]
    text = ARN.sub("<aws-arn>", text)
    text = ACCOUNT_ID.sub("<aws-account-id>", text)
    text = AWS_ACCESS_KEY.sub("<aws-access-key>", text)
    text = GITHUB_TOKEN.sub("<github-token>", text)
    text = JWT.sub("<jwt>", text)
    return EMAIL.sub("<email>", text)


def safe_identifier(value: Any) -> str:
    """Keep structural identifiers while removing instance keys and prose."""

    text = INSTANCE_KEY.sub("[<instance-key>]", redact_text(value))
    return re.sub(r"[^A-Za-z0-9_.:/<>\[\]-]", "?", text)[:256]


def changed_paths(before: Any, after: Any) -> set[str]:
    """Return only changed top-level attributes, never nested map keys or values."""

    if isinstance(before, dict) and isinstance(after, dict):
        return {
            safe_identifier(key)
            for key in before.keys() | after.keys()
            if before.get(key, MISSING) != after.get(key, MISSING)
        }
    return {"<root>"} if before != after else set()


def classify_actions(actions: Sequence[str]) -> str:
    action_set = set(actions)
    if {"create", "delete"}.issubset(action_set):
        return "replace"
    for name in ("create", "update", "delete", "read", "no-op"):
        if name in action_set:
            return name
    return "other"


def _change_projection(resource: dict) -> dict:
    change = resource.get("change") or {}
    actions = [redact_text(action) for action in change.get("actions", [])]
    return {
        "address": safe_identifier(resource.get("address", "<unknown>")),
        "module_address": safe_identifier(resource.get("module_address", "")),
        "mode": safe_identifier(resource.get("mode", "managed")),
        "type": safe_identifier(resource.get("type", "<unknown>")),
        "name": safe_identifier(resource.get("name", "<unknown>")),
        "provider_name": safe_identifier(resource.get("provider_name", "")),
        "actions": actions,
        "classification": classify_actions(actions),
        "changed_paths": sorted(
            changed_paths(change.get("before", MISSING), change.get("after", MISSING))
        ),
        "replace_paths": sorted(
            {
                safe_identifier(path[0]) if path else "<root>"
                for path in (change.get("replace_paths") or [])
            }
        ),
    }


def _counts(changes: Sequence[dict]) -> dict[str, int]:
    classifications = ("create", "update", "delete", "replace", "read", "no-op", "other")
    counts = {name: 0 for name in classifications}
    for change in changes:
        counts[change["classification"]] += 1
    return counts


def build_review(
    plan: dict, *, layer: str, metadata: dict[str, str] | None = None
) -> dict:
    changes = [
        projection
        for item in plan.get("resource_changes", [])
        if (projection := _change_projection(item))["classification"] != "no-op"
    ]
    drift = [
        projection
        for item in plan.get("resource_drift", [])
        if (projection := _change_projection(item))["classification"] != "no-op"
    ]
    counts = _counts(changes)
    signals: list[dict[str, str]] = []
    if counts["delete"] or counts["replace"]:
        signals.append(
            {
                "severity": "high",
                "kind": "destructive-change",
                "message": (
                    f"plan contains {counts['delete']} delete(s) and "
                    f"{counts['replace']} replacement(s)"
                ),
            }
        )
    security_changes = sorted(
        {
            change["address"]
            for change in changes
            if change["classification"] != "no-op"
            and change["type"].startswith(SECURITY_SENSITIVE_TYPES)
        }
    )
    if security_changes:
        signals.append(
            {
                "severity": "review",
                "kind": "security-sensitive-resource",
                "message": f"{len(security_changes)} security-sensitive resource(s) change",
            }
        )

    output_changes = []
    for name, output in sorted((plan.get("output_changes") or {}).items()):
        actions = [redact_text(action) for action in (output.get("actions") or [])]
        output_changes.append(
            {
                "name": safe_identifier(name),
                "actions": actions,
                "classification": classify_actions(actions),
            }
        )

    check_counts: dict[str, int] = {}
    for check in plan.get("checks") or []:
        status = redact_text(check.get("status", "unknown"))
        check_counts[status] = check_counts.get(status, 0) + 1

    return {
        "schema_version": SCHEMA_VERSION,
        "layer": safe_identifier(layer),
        "metadata": metadata or {},
        "format_version": redact_text(plan.get("format_version", "unknown")),
        "opentofu_version": redact_text(
            plan.get("terraform_version", plan.get("tofu_version", "unknown"))
        ),
        "errored": bool(plan.get("errored", False)),
        "summary": counts,
        "review_signals": signals,
        "resource_changes": changes,
        "resource_drift": drift,
        "output_changes": output_changes,
        "check_counts": check_counts,
    }


def _summary_table(review: dict) -> str:
    counts = review["summary"]
    return (
        "| Create | Update | Delete | Replace | Read |\n"
        "|---:|---:|---:|---:|---:|\n"
        f"| {counts['create']} | {counts['update']} | {counts['delete']} | "
        f"{counts['replace']} | {counts['read']} |\n"
    )


def _markdown_code(value: Any) -> str:
    safe = html.escape(str(value), quote=False).replace("`", "\\`")
    return f"`{safe}`"


def render_review(review: dict) -> str:
    lines = [
        f"## OpenTofu plan: {_markdown_code(review['layer'])}",
        "",
        _summary_table(review).rstrip(),
    ]
    if review["review_signals"]:
        lines.extend(["", "### Deterministic review signals", ""])
        lines.extend(
            f"- **{html.escape(signal['severity'], quote=False)}** · "
            f"{html.escape(signal['message'], quote=False)}"
            for signal in review["review_signals"]
        )
    actionable = [
        item for item in review["resource_changes"] if item["classification"] != "no-op"
    ]
    if actionable:
        lines.extend(["", "### Resource actions", ""])
        for item in actionable[:100]:
            changed = ", ".join(
                _markdown_code(path) for path in item["changed_paths"][:12]
            )
            suffix = f" — {changed}" if changed else ""
            lines.append(
                f"- **{html.escape(item['classification'], quote=False)}** "
                f"{_markdown_code(item['address'])}{suffix}"
            )
        if len(actionable) > 100:
            lines.append(f"- … {len(actionable) - 100} additional resource action(s)")
    lines.extend(
        [
            "",
            "> This report intentionally excludes before/after values, variables, prior state, "
            "and the binary plan.",
        ]
    )
    return "\n".join(lines) + "\n"


def _write_result(
    *,
    out_dir: Path,
    layer: str,
    mode: str,
    status: str,
    init_exit: int,
    validate_exit: int,
    plan_exit: int | None,
    review: dict | None = None,
    metadata: dict[str, str] | None = None,
    failure_stage: str | None = None,
    denied_action: str | None = None,
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    result = {
        "schema_version": SCHEMA_VERSION,
        "layer": layer,
        "mode": mode,
        "status": status,
        "init_exit_code": init_exit,
        "validate_exit_code": validate_exit,
        "plan_exit_code": plan_exit,
        "summary": review["summary"] if review else None,
        "review_signals": review["review_signals"] if review else [],
        "metadata": metadata or {},
        "failure": (
            {"stage": failure_stage, "denied_action": denied_action}
            if failure_stage
            else None
        ),
    }
    (out_dir / "result.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    if review:
        (out_dir / "review.json").write_text(
            json.dumps(review, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        summary = render_review(review)
    else:
        safe_layer = _markdown_code(layer)
        heading = "OpenTofu live plan" if mode == "live" else "OpenTofu static validation"
        summary = f"## {heading}: {safe_layer}\n\n"
        summary += f"- Init (`-backend=false`): `{init_exit}`\n"
        summary += f"- Validate: `{validate_exit}`\n"
        if mode == "live":
            summary += f"- Plan: `{plan_exit}`\n"
        summary += f"- Result: **{status}**\n\n"
        if failure_stage:
            summary += f"- Failed stage: `{failure_stage}`\n"
        if denied_action:
            summary += f"- Denied AWS action: `{denied_action}`\n"
        summary += (
            "\n> No raw logs, state, variables, or binary plan are included.\n"
            if mode == "live"
            else "\n> No AWS credentials were used and no live plan was produced.\n"
        )
    (out_dir / "summary.md").write_text(summary, encoding="utf-8")


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    static = subparsers.add_parser("static")
    static.add_argument("--layer", required=True)
    static.add_argument("--init-exit", type=int, required=True)
    static.add_argument("--validate-exit", type=int, required=True)
    static.add_argument("--out-dir", type=Path, required=True)

    live = subparsers.add_parser("live")
    live.add_argument("--layer", required=True)
    live.add_argument("--init-exit", type=int, required=True)
    live.add_argument("--validate-exit", type=int, required=True)
    live.add_argument("--plan-exit", type=int, required=True)
    live.add_argument("--plan-json", type=Path)
    live.add_argument("--failure-stage", choices=("init", "validate", "plan"))
    live.add_argument("--denied-action")
    live.add_argument("--out-dir", type=Path, required=True)
    for command in (static, live):
        command.add_argument("--repository", default="unknown")
        command.add_argument("--head-sha", default="unknown")
        command.add_argument("--merge-sha", default="unknown")
        command.add_argument("--run-id", default="unknown")
        command.add_argument("--run-attempt", default="unknown")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    metadata = {
        "repository": redact_text(args.repository),
        "head_sha": redact_text(args.head_sha),
        "merge_sha": redact_text(args.merge_sha),
        "run_id": redact_text(args.run_id),
        "run_attempt": redact_text(args.run_attempt),
    }
    if args.command == "static":
        passed = args.init_exit == 0 and args.validate_exit == 0
        _write_result(
            out_dir=args.out_dir,
            layer=args.layer,
            mode="static",
            status="passed" if passed else "failed",
            init_exit=args.init_exit,
            validate_exit=args.validate_exit,
            plan_exit=None,
            metadata=metadata,
        )
        return 0

    review = None
    if args.denied_action and not AWS_ACTION.fullmatch(args.denied_action):
        raise SystemExit("denied action has an unsafe format")
    if args.plan_exit in (0, 2) and args.plan_json and args.plan_json.is_file():
        review = build_review(
            json.loads(args.plan_json.read_text(encoding="utf-8")),
            layer=args.layer,
            metadata=metadata,
        )
    passed = args.init_exit == 0 and args.validate_exit == 0 and args.plan_exit in (0, 2)
    _write_result(
        out_dir=args.out_dir,
        layer=args.layer,
        mode="live",
        status="passed" if passed else "failed",
        init_exit=args.init_exit,
        validate_exit=args.validate_exit,
        plan_exit=args.plan_exit,
        review=review,
        metadata=metadata,
        failure_stage=args.failure_stage,
        denied_action=args.denied_action,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
