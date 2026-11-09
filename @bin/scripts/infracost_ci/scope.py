"""Decide which layers the Infracost PR check estimates on each side of the diff."""

from __future__ import annotations

from pathlib import PurePosixPath
from typing import Sequence

from tofu_plan_ci.discover import discover_from_paths

# Changes to the check itself estimate this layer, so a PR that only touches the workflow
# or this package still proves the pipeline end to end. It is cheap to price and holds a
# real EC2 instance, so the comment shows a non-zero estimate.
SMOKE_LAYERS = ("shared/us-east-1/tools-vpn-server",)

SELF_PATHS = (
    ".github/workflows/infracost.yml",
    "@bin/scripts/infracost_ci/",
    "@bin/scripts/tofu_plan_ci/discover.py",
)


def _is_self(path: str) -> bool:
    return any(path == item or (item.endswith("/") and path.startswith(item)) for item in SELF_PATHS)


def scope(
    *,
    changed_paths: Sequence[str],
    active_roots: set[str],
    disabled_roots: set[str],
    base_active_roots: set[str],
    base_disabled_roots: set[str],
    accounts: set[str],
) -> dict:
    """Return the head and base layer sets for an Infracost diff.

    Unlike the plan CI there is no allowlist and no layer cap: estimating is offline HCL
    parsing, so every affected active layer is in scope. A layer deleted by the PR is
    estimated on the base side only, so the diff shows its cost going away instead of
    silently dropping it.
    """

    result = discover_from_paths(
        changed_paths=changed_paths,
        active_roots=active_roots,
        disabled_roots=disabled_roots,
        base_active_roots=base_active_roots,
        base_disabled_roots=base_disabled_roots,
        accounts=accounts,
        allow_layers=None,
        max_layers=len(active_roots | base_active_roots) + 1,
    )
    head = set(result["layers"])
    reasons = [
        reason
        for reason in result["scope_reasons"]
        # The plan CI's own self-test does not concern this check.
        if not reason.startswith("plan workflow implementation changed")
    ]

    self_changes = sorted(p for p in changed_paths if _is_self(PurePosixPath(p).as_posix()))
    if self_changes:
        smoke = {layer for layer in SMOKE_LAYERS if layer in active_roots}
        if smoke - head:
            reasons.append(f"Infracost check changed: {self_changes[0]}")
        head |= smoke

    deleted = set(result["deleted_layers"])
    base = (head & base_active_roots) | deleted
    skipped = [
        item
        for item in result["skipped"]
        if item["path"] not in deleted
    ]
    return {
        "head_layers": sorted(head),
        "base_layers": sorted(base),
        "deleted_layers": sorted(deleted),
        "new_layers": sorted(head - base_active_roots),
        "scope_reasons": sorted(reasons),
        "skipped": skipped,
    }


def render_markdown(result: dict) -> str:
    lines = ["## Infracost scope", ""]
    if not result["head_layers"] and not result["base_layers"]:
        lines.append("No active OpenTofu layer is affected by this change; Infracost did not run.")
    else:
        lines.append(
            f"Estimating **{len(result['head_layers'])}** layer(s) at the PR head and "
            f"**{len(result['base_layers'])}** at the base."
        )
        for title, key in (
            ("Layers", "head_layers"),
            ("Deleted by this PR (base only)", "deleted_layers"),
            ("New in this PR (head only)", "new_layers"),
        ):
            if result[key]:
                lines.extend(["", f"### {title}", ""])
                lines.extend(f"- `{layer}`" for layer in result[key])
    if result["scope_reasons"]:
        lines.extend(["", "### Expanded scope", ""])
        lines.extend(f"- {reason}" for reason in result["scope_reasons"])
    if result["skipped"]:
        lines.extend(["", "### Not estimated", ""])
        lines.extend(f"- `{item['path']}` — {item['reason']}" for item in result["skipped"])
    return "\n".join(lines) + "\n"
