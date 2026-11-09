"""Command line entry point.

    python -m infracost_ci config --all --out infracost.generated.yml
    python -m infracost_ci scope --base <sha> --head <sha> --out-dir <dir>
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path, PurePosixPath
from typing import Sequence

from tofu_plan_ci.discover import (
    account_names,
    git_changed_paths,
    revision_roots,
    working_tree_roots,
)

from . import config, scope


def _github_output(name: str, value: str) -> None:
    path = os.environ.get("GITHUB_OUTPUT")
    if path:
        with open(path, "a", encoding="utf-8") as handle:
            handle.write(f"{name}={value}\n")


def normalise_layer(layer: str) -> str:
    """Accept ``./a/b`` and ``a/b/`` as ``a/b``, as a shell completion would type them."""
    path = PurePosixPath(layer)
    if path.is_absolute() or ".." in path.parts:
        raise SystemExit(f"layer must be a repository-relative path: {layer!r}")
    return path.as_posix()


def run_config(args: argparse.Namespace) -> int:
    root = args.root.resolve()
    active, _ = working_tree_roots(root, account_names(root))
    requested = {normalise_layer(layer) for layer in args.layer}
    layers = active if args.all else requested
    unknown = sorted(requested - active)
    if unknown:
        raise SystemExit(f"not an active layer: {', '.join(unknown)}")
    text = config.render(layers, schema=args.schema)
    if args.out:
        args.out.write_text(text, encoding="utf-8")
    else:
        print(text, end="")
    return 0


def run_scope(args: argparse.Namespace) -> int:
    root = args.root.resolve()
    accounts = account_names(root)
    active, disabled = working_tree_roots(root, accounts)
    base_active, base_disabled = revision_roots(root, args.base, accounts)
    result = scope.scope(
        changed_paths=git_changed_paths(root, args.base, args.head),
        active_roots=active,
        disabled_roots=disabled,
        base_active_roots=base_active,
        base_disabled_roots=base_disabled,
        accounts=accounts,
    )
    out = args.out_dir
    out.mkdir(parents=True, exist_ok=True)
    config.write(out / "head.yml", result["head_layers"], schema=args.schema)
    config.write(out / "base.yml", result["base_layers"], schema=args.schema)
    (out / "scope.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    markdown = scope.render_markdown(result)
    (out / "scope.md").write_text(markdown, encoding="utf-8")

    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as handle:
            handle.write(markdown)
    has_layers = bool(result["head_layers"] or result["base_layers"])
    _github_output("has_layers", "true" if has_layers else "false")
    _github_output("has_base_layers", "true" if result["base_layers"] else "false")
    _github_output("layer_count", str(len(result["head_layers"])))
    print(markdown, end="")
    return 0


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="infracost_ci", description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--schema", choices=config.SCHEMAS, default="0.1")
    commands = parser.add_subparsers(dest="command", required=True)

    cfg = commands.add_parser("config", help="render an Infracost config for layers")
    which = cfg.add_mutually_exclusive_group(required=True)
    which.add_argument("--all", action="store_true", help="every active layer")
    which.add_argument("--layer", action="append", default=[], help="one layer (repeatable)")
    cfg.add_argument("--out", type=Path)

    scp = commands.add_parser("scope", help="scope a PR to the layers it affects")
    scp.add_argument("--base", required=True)
    scp.add_argument("--head", default="HEAD")
    scp.add_argument("--out-dir", type=Path, required=True)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    return run_config(args) if args.command == "config" else run_scope(args)


if __name__ == "__main__":
    raise SystemExit(main())
