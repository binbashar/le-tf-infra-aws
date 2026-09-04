"""CLI for the version-support guardrail.

The only module that decides whether a run fails. Side effects that talk to Slack
or GitHub live in the workflow, not here.
"""

from __future__ import annotations

import argparse
import json
import os
from datetime import date, timezone, datetime

import boto3

from version_support import discover as discover_module
from version_support import report as report_module
from version_support.lifecycle import DEFAULT_LEAD_DAYS, Finding, LookupUnavailable, evaluate


def collect(root: str, today: date, lead_days: int) -> tuple[list[Finding], list[str]]:
    """(findings, parse_errors) for the tree at `root`. Raises LookupUnavailable."""
    pins, errors = discover_module.discover(root)
    if not pins:
        # Nothing to ask AWS about -- do not build clients we cannot use, and do
        # not risk a spurious LookupUnavailable on a scan that had nothing to check.
        return [], errors

    try:
        # Construction is inside the guard on purpose: boto3 can fail before any
        # network call -- NoRegionError when no region resolves, for one -- and
        # evaluate()'s own try/except cannot see that, because these expressions
        # are evaluated before its body runs. Left outside, a misconfigured
        # workflow step would crash the gate instead of degrading it.
        eks_client = boto3.client("eks")
        rds_client = boto3.client("rds")
    except Exception as exc:  # noqa: BLE001 - boto3 client construction can fail
        # outside botocore's documented exception hierarchy: an empty-but-present
        # region raises a bare ValueError from botocore.endpoint, reproduced with
        # AWS_DEFAULT_REGION="". Anything raised while building these two clients
        # means "AWS is not usable", never "our code has a bug" -- and the whole
        # point of this module is that an AWS problem must not crash the gate.
        raise LookupUnavailable(str(exc)) from exc

    findings = evaluate(
        pins,
        eks_client=eks_client,
        rds_client=rds_client,
        today=today,
        lead_days=lead_days,
    )
    return findings, errors


def _write_github_output(key: str, value: str) -> None:
    path = os.environ.get("GITHUB_OUTPUT")
    if not path:
        return
    with open(path, "a", encoding="utf-8") as handle:
        handle.write(f"{key}={value}\n")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="version_support")
    parser.add_argument(
        "--mode",
        choices=("pr", "cron", "table"),
        required=True,
        help="Which mode to run: pr gate, cron sweep, or table generation.",
    )
    parser.add_argument(
        "--root", default=".", help="Root of the tree to scan (default: current directory)."
    )
    parser.add_argument(
        "--lead-days",
        type=int,
        default=DEFAULT_LEAD_DAYS,
        help="Days before end of support that a version is flagged SOON.",
    )
    parser.add_argument(
        "--out",
        default="docs/version-support/status.md",
        help="Markdown status file path written by table mode.",
    )
    parser.add_argument(
        "--summary-out",
        default=None,
        help="Optional path to write the cron mode Slack JSON payload.",
    )
    parser.add_argument(
        "--issue-out",
        default=None,
        help="Optional path to write the cron mode tracking issue body.",
    )
    args = parser.parse_args(argv)

    today = datetime.now(timezone.utc).date()

    try:
        findings, errors = collect(args.root, today, args.lead_days)
    except LookupUnavailable as exc:
        # A check that silently passes when it could not run is worse than none.
        message = f"version-support: AWS lookup unavailable - the check did NOT run ({exc})"
        # stdout, not stderr: GitHub parses workflow commands from stdout only, so
        # a ::warning:: on stderr renders no annotation at all -- which would make
        # this failure quiet, the one outcome this handler exists to prevent.
        print(f"::warning::{message}")
        _write_github_output("ran", "false")
        return 0

    for error in errors:
        print(f"::warning::version-support: could not parse {error}")

    print(report_module.terminal_table(findings))
    _write_github_output("ran", "true")

    if args.mode == "table":
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        with open(args.out, "w", encoding="utf-8") as handle:
            handle.write(report_module.markdown_table(findings, today))
        print(f"\nwrote {args.out}")
        return 0

    if args.mode == "pr":
        for line in report_module.annotations(findings):
            print(line)
        blocking = report_module.blocking_findings(findings)
        if blocking:
            print(
                f"\n{len(blocking)} active layer(s) pin a version in extended support."
            )
            return 1
        return 0

    elif args.mode == "cron":
        attention = report_module.attention_findings(findings)
        _write_github_output("has_findings", "true" if attention else "false")
        if args.summary_out:
            repository = os.environ.get("GITHUB_REPOSITORY", "")
            run_url = (
                f"{os.environ.get('GITHUB_SERVER_URL', 'https://github.com')}/"
                f"{repository}/actions/runs/{os.environ.get('GITHUB_RUN_ID', '')}"
            )
            payload = report_module.slack_payload(
                findings, repository=repository, run_url=run_url
            )
            with open(args.summary_out, "w", encoding="utf-8") as handle:
                json.dump(payload, handle)
        if args.issue_out:
            with open(args.issue_out, "w", encoding="utf-8") as handle:
                handle.write(report_module.issue_body(findings, today))
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
