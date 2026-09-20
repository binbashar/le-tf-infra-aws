"""Discover active OpenTofu root modules affected by a Git diff."""

from __future__ import annotations

import argparse
import html
import json
import subprocess
from pathlib import Path, PurePosixPath
from typing import Iterable, Sequence

from . import SCHEMA_VERSION
from .policy import changed_hcl_documents, git_hcl_patch, live_plan_blockers

POC_SELF_TEST_PATHS = (
    ".github/workflows/tofu-plan-poc.yml",
    "@bin/scripts/tofu_plan_ci/",
)


def _is_disabled(path: str) -> bool:
    return any(part.rstrip().endswith("--") for part in PurePosixPath(path).parts)


def _normalise_relative(path: str) -> str:
    candidate = PurePosixPath(path)
    if candidate.is_absolute() or ".." in candidate.parts:
        raise ValueError(f"path must be repository-relative: {path!r}")
    normalized = candidate.as_posix()
    return normalized[2:] if normalized.startswith("./") else normalized


def account_names(root: Path) -> set[str]:
    return {
        child.name
        for child in root.iterdir()
        if child.is_dir() and (child / "config" / "account.tfvars").is_file()
    }


def working_tree_roots(root: Path, accounts: set[str]) -> tuple[set[str], set[str]]:
    active: set[str] = set()
    disabled: set[str] = set()
    for config in root.rglob("config.tf"):
        relative = config.relative_to(root).as_posix()
        if ".terraform" in PurePosixPath(relative).parts:
            continue
        if not relative.split("/", 1)[0] in accounts:
            continue
        layer = relative.removesuffix("/config.tf")
        (disabled if _is_disabled(layer) else active).add(layer)
    return active, disabled


def revision_roots(
    root: Path, revision: str, accounts: set[str]
) -> tuple[set[str], set[str]]:
    if not revision:
        return set(), set()
    proc = subprocess.run(
        ["git", "ls-tree", "-r", "-z", "--name-only", revision],
        cwd=root,
        check=True,
        stdout=subprocess.PIPE,
    )
    active: set[str] = set()
    disabled: set[str] = set()
    for raw_path in proc.stdout.split(b"\0"):
        if not raw_path:
            continue
        path = raw_path.decode("utf-8", errors="surrogateescape")
        if not path.endswith("/config.tf") or path.split("/", 1)[0] not in accounts:
            continue
        layer = path.removesuffix("/config.tf")
        (disabled if _is_disabled(layer) else active).add(layer)
    return active, disabled


def git_changed_paths(root: Path, base: str, head: str) -> list[str]:
    proc = subprocess.run(
        ["git", "diff", "--name-only", "-z", base, head, "--"],
        cwd=root,
        check=True,
        stdout=subprocess.PIPE,
    )
    return [
        path.decode("utf-8", errors="surrogateescape")
        for path in proc.stdout.split(b"\0")
        if path
    ]


def _containing_root(path: str, roots: Iterable[str]) -> str | None:
    candidates = [
        layer for layer in roots if path == layer or path.startswith(f"{layer}/")
    ]
    return max(candidates, key=len) if candidates else None


def discover_from_paths(
    *,
    changed_paths: Sequence[str],
    active_roots: set[str],
    disabled_roots: set[str],
    base_active_roots: set[str],
    base_disabled_roots: set[str],
    accounts: set[str],
    allow_layers: set[str] | None = None,
    max_layers: int = 3,
    live_blockers: Sequence[str] = (),
) -> dict:
    """Resolve changed files to root modules without assuming a fixed depth."""

    selected: set[str] = set()
    deleted_layers: set[str] = set()
    self_test_requested = False
    skipped: dict[tuple[str, str], dict[str, str]] = {}
    scope_reasons: set[str] = set()
    all_active = active_roots | base_active_roots
    all_disabled = disabled_roots | base_disabled_roots

    def skip(path: str, reason: str) -> None:
        skipped[(path, reason)] = {"path": path, "reason": reason}

    for raw_path in changed_paths:
        path = _normalise_relative(raw_path)
        parts = PurePosixPath(path).parts
        if not parts:
            continue

        if path == POC_SELF_TEST_PATHS[0] or path.startswith(POC_SELF_TEST_PATHS[1]):
            self_test_requested = True
            scope_reasons.add(f"POC implementation changed: {path}")
            continue

        if parts[0] == "config":
            selected.update(active_roots)
            scope_reasons.add(f"project configuration changed: {path}")
            continue

        account = parts[0]
        if account in accounts and len(parts) > 1 and parts[1] == "config":
            selected.update(layer for layer in active_roots if layer.startswith(f"{account}/"))
            scope_reasons.add(f"account configuration changed: {path}")
            continue

        layer = _containing_root(path, active_roots)
        if layer:
            selected.add(layer)
            continue

        deleted_layer = _containing_root(path, base_active_roots - active_roots)
        if deleted_layer:
            deleted_layers.add(deleted_layer)
            skip(deleted_layer, "layer no longer exists at the PR head; it cannot be planned")
            continue

        disabled_layer = _containing_root(path, all_disabled)
        if disabled_layer:
            skip(disabled_layer, "disabled layer (path segment ends in --)")
            continue

        # A file can sit above a root module only for project/account configuration,
        # which is handled above. Everything else is intentionally ignored.
        if _containing_root(path, all_active):
            raise AssertionError(f"unhandled active layer path: {path}")

    candidate_layers = sorted(selected)
    allowed = allow_layers or set()
    if self_test_requested:
        selected.update(active_roots & allowed)
        candidate_layers = sorted(set(candidate_layers) | selected)
    if allowed:
        for layer in sorted(selected - allowed):
            skip(layer, "outside the POC layer allowlist")
        selected.intersection_update(allowed)

    blocked_reason = None
    if deleted_layers:
        blocked_reason = "deleted layer(s) cannot be planned: " + ", ".join(
            sorted(deleted_layers)
        )
    if len(selected) > max_layers:
        limit_reason = (
            f"{len(selected)} layers are in scope, above the POC safety limit of "
            f"{max_layers}; no subset was selected"
        )
        blocked_reason = (
            f"{blocked_reason}; {limit_reason}" if blocked_reason else limit_reason
        )
        selected.clear()

    return {
        "schema_version": SCHEMA_VERSION,
        "layers": sorted(selected),
        "candidate_layers": candidate_layers,
        "scope_reasons": sorted(scope_reasons),
        "skipped": sorted(skipped.values(), key=lambda item: (item["path"], item["reason"])),
        "blocked_reason": blocked_reason,
        "live_eligible": not live_blockers,
        "live_blockers": sorted(set(live_blockers)),
    }


def manual_discovery(
    *,
    layer: str,
    active_roots: set[str],
    disabled_roots: set[str],
    allow_layers: set[str] | None,
) -> dict:
    layer = _normalise_relative(layer)
    result = {
        "schema_version": SCHEMA_VERSION,
        "layers": [],
        "candidate_layers": [layer],
        "scope_reasons": ["manual workflow dispatch"],
        "skipped": [],
        "blocked_reason": None,
        "live_eligible": True,
        "live_blockers": [],
    }
    if layer in disabled_roots:
        result["blocked_reason"] = f"requested layer is disabled: {layer}"
    elif layer not in active_roots:
        result["blocked_reason"] = f"requested layer is not an active root module: {layer}"
    elif allow_layers and layer not in allow_layers:
        result["blocked_reason"] = f"requested layer is outside the POC allowlist: {layer}"
    else:
        result["layers"] = [layer]
    return result


def render_markdown(result: dict, *, base: str = "", head: str = "") -> str:
    def safe(value: object) -> str:
        return html.escape(str(value), quote=False).replace("`", "\\`")

    lines = ["## OpenTofu layer discovery", ""]
    if base or head:
        lines.extend(
            [
                f"- Base: `{safe(base[:12] or 'n/a')}`",
                f"- Head: `{safe(head[:12] or 'n/a')}`",
            ]
        )
    lines.append(f"- Selected layers: **{len(result['layers'])}**")
    lines.append(
        "- Candidate layers before POC scoping: "
        f"**{len(result['candidate_layers'])}**"
    )
    lines.append(
        "- Credentialed live plan: "
        f"**{'eligible' if result.get('live_eligible', True) else 'suppressed'}**"
    )
    if result.get("blocked_reason"):
        lines.extend(["", f"> **Blocked:** {safe(result['blocked_reason'])}"])
    if result["layers"]:
        lines.extend(["", "### Selected", ""])
        lines.extend(f"- `{safe(layer)}`" for layer in result["layers"])
    if result.get("scope_reasons"):
        lines.extend(["", "### Expanded scope", ""])
        lines.extend(f"- {safe(reason)}" for reason in result["scope_reasons"])
    if result.get("live_blockers"):
        lines.extend(["", "### Live-plan policy", ""])
        lines.extend(f"- {safe(reason)}" for reason in result["live_blockers"])
    if result.get("skipped"):
        lines.extend(["", "### Not planned by this POC", ""])
        lines.extend(
            f"- `{safe(item['path'])}` — {safe(item['reason'])}"
            for item in result["skipped"]
        )
    return "\n".join(lines) + "\n"


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--base", default="")
    parser.add_argument("--head", default="HEAD")
    parser.add_argument("--layer", help="Select one layer for workflow_dispatch")
    parser.add_argument("--allow-layer", action="append", default=[])
    parser.add_argument("--max-layers", type=int, default=3)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--markdown-out", type=Path)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    root = args.root.resolve()
    accounts = account_names(root)
    active, disabled = working_tree_roots(root, accounts)
    allowed = {_normalise_relative(layer) for layer in args.allow_layer if layer}

    if args.layer:
        result = manual_discovery(
            layer=args.layer,
            active_roots=active,
            disabled_roots=disabled,
            allow_layers=allowed,
        )
    else:
        if not args.base:
            raise SystemExit("--base is required unless --layer is provided")
        base_active, base_disabled = revision_roots(root, args.base, accounts)
        changed_paths = git_changed_paths(root, args.base, args.head)
        result = discover_from_paths(
            changed_paths=changed_paths,
            active_roots=active,
            disabled_roots=disabled,
            base_active_roots=base_active,
            base_disabled_roots=base_disabled,
            accounts=accounts,
            allow_layers=allowed,
            max_layers=args.max_layers,
            live_blockers=live_plan_blockers(
                changed_paths,
                git_hcl_patch(root, args.base, args.head),
                changed_hcl_documents(root, changed_paths),
            ),
        )

    result.update({"base": args.base, "head": args.head})
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    if args.markdown_out:
        args.markdown_out.parent.mkdir(parents=True, exist_ok=True)
        args.markdown_out.write_text(
            render_markdown(result, base=args.base, head=args.head), encoding="utf-8"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
