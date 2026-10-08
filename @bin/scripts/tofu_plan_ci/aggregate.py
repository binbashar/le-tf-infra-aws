"""Render the stable GitHub check summary and determine its outcome."""

from __future__ import annotations

import argparse
import html
import json
from pathlib import Path
from typing import Sequence

from . import SCHEMA_VERSION


def load_results(directory: Path) -> list[dict]:
    return [
        json.loads(path.read_text(encoding="utf-8"))
        for path in sorted(directory.rglob("result.json"))
    ]


def aggregate(
    *,
    discovery: dict,
    results: Sequence[dict],
    require_live: bool,
    expected_metadata: dict[str, str] | None = None,
) -> tuple[str, list[str]]:
    reasons: list[str] = []
    if discovery.get("schema_version") != SCHEMA_VERSION:
        reasons.append("unsupported discovery schema")
    invalid_schema = sorted(
        str(result.get("layer", "<unknown>"))
        for result in results
        if result.get("schema_version") != SCHEMA_VERSION
    )
    if invalid_schema:
        reasons.append(
            "unsupported result schema for: " + ", ".join(invalid_schema)
        )
    by_layer = {result["layer"]: result for result in results}
    if len(by_layer) != len(results):
        reasons.append("duplicate layer results were found in downloaded artifacts")
    expected = set(discovery.get("layers", []))
    missing = sorted(expected - by_layer.keys())
    if discovery.get("blocked_reason"):
        reasons.append(discovery["blocked_reason"])
    if missing:
        reasons.append("missing result for: " + ", ".join(missing))
    failed = sorted(
        result["layer"] for result in results if result.get("status") != "passed"
    )
    if failed:
        reasons.append("failed layer(s): " + ", ".join(failed))
    if require_live:
        static = sorted(
            result["layer"] for result in results if result.get("mode") != "live"
        )
        if static:
            reasons.append("live plan required but not produced for: " + ", ".join(static))
    if expected_metadata:
        mismatched = sorted(
            result.get("layer", "<unknown>")
            for result in results
            if any(
                str((result.get("metadata") or {}).get(key, "")) != str(value)
                for key, value in expected_metadata.items()
            )
        )
        if mismatched:
            reasons.append(
                "artifact provenance does not match this workflow run for: "
                + ", ".join(mismatched)
            )
    return ("fail" if reasons else "pass"), reasons


def render_markdown(
    *,
    discovery: dict,
    results: Sequence[dict],
    gate: str,
    reasons: Sequence[str],
    require_live: bool,
    analysis_markdown: str | None,
    analysis_status: str,
) -> str:
    def safe(value: object) -> str:
        return html.escape(str(value), quote=False).replace("`", "\\`")

    lines = [
        "# OpenTofu plan POC",
        "",
        f"**Outcome:** {'PASS' if gate == 'pass' else 'FAIL'}",
        "",
        "| Layer | Mode | Result | Create | Update | Delete | Replace |",
        "|---|---|---|---:|---:|---:|---:|",
    ]
    for result in sorted(results, key=lambda item: item["layer"]):
        counts = result.get("summary") or {}
        lines.append(
            f"| `{safe(result['layer'])}` | {safe(result['mode'])} | "
            f"{safe(result['status'])} | "
            f"{counts.get('create', '—')} | {counts.get('update', '—')} | "
            f"{counts.get('delete', '—')} | {counts.get('replace', '—')} |"
        )
    if not results:
        lines.append("| _No POC layer affected_ | — | skipped | — | — | — | — |")

    if reasons:
        lines.extend(["", "## Blocking reasons", ""])
        lines.extend(f"- {safe(reason)}" for reason in reasons)
    if discovery.get("skipped"):
        lines.extend(["", "## Outside this POC run", ""])
        lines.extend(
            f"- `{safe(item['path'])}` — {safe(item['reason'])}"
            for item in discovery["skipped"]
        )
    if discovery.get("live_blockers"):
        lines.extend(["", "## Credentialed plan suppressed", ""])
        lines.extend(f"- {safe(reason)}" for reason in discovery["live_blockers"])
    if not require_live and results:
        lines.extend(
            [
                "",
                "> Live planning is not enabled. Static mode runs `init -backend=false` and "
                "`validate` without AWS credentials.",
            ]
        )
    if analysis_markdown:
        lines.extend(["", analysis_markdown.rstrip()])
    elif results:
        lines.extend(
            [
                "",
                "## LLM-assisted explanation",
                "",
                f"Not available for this run (`{safe(analysis_status)}`). The deterministic "
                "result above is unaffected.",
            ]
        )
    lines.extend(
        [
            "",
            "## Evidence",
            "",
            "Sanitized JSON and Markdown reports are attached to this workflow run as "
            "artifacts. Binary plans, prior state, variables, and before/after values are "
            "never uploaded.",
        ]
    )
    return "\n".join(lines) + "\n"


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--discovery", type=Path, required=True)
    parser.add_argument("--reports-dir", type=Path, required=True)
    parser.add_argument("--require-live", action="store_true")
    parser.add_argument("--analysis-markdown", type=Path)
    parser.add_argument("--analysis-status", default="disabled")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--github-output", type=Path)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    discovery = json.loads(args.discovery.read_text(encoding="utf-8"))
    results = load_results(args.reports_dir)
    gate, reasons = aggregate(
        discovery=discovery, results=results, require_live=args.require_live
    )
    analysis = None
    if args.analysis_markdown and args.analysis_markdown.is_file():
        analysis = args.analysis_markdown.read_text(encoding="utf-8")
    markdown = render_markdown(
        discovery=discovery,
        results=results,
        gate=gate,
        reasons=reasons,
        require_live=args.require_live,
        analysis_markdown=analysis,
        analysis_status=args.analysis_status,
    )
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(markdown, encoding="utf-8")
    if args.github_output:
        with args.github_output.open("a", encoding="utf-8") as output:
            output.write(f"gate={gate}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
