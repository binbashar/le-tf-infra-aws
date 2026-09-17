#!/usr/bin/env python3
"""Redact a `tofu plan` excerpt before pasting it into a PR on this public repo.

Why Python and not `sed`: BSD/macOS `sed -E` silently ignores `\\b`, so the
obvious `sed -E 's/\\b[0-9]{12}\\b/.../'` is a no-op on a Mac and leaves every
account ID in place. BSD wants `[[:<:]]`/`[[:>:]]` and GNU wants `\\b`, so no
single sed expression is portable. `re` behaves the same on both.

Order matters: UUIDs are redacted before bare digit runs, otherwise `\\d{12}`
chews through a UUID's digit groups first and the scan passes on the mangled
result.

Pattern matching alone is not enough. Route53 zone IDs, ACM validation tokens
and PGP/password blobs have no distinctive shape, so they are also redacted by
the attribute name that carries them.

Usage:
    python3 @bin/scripts/redact_plan.py /tmp/plan-clean.txt > /tmp/plan-redacted.txt
    python3 @bin/scripts/redact_plan.py --scan /tmp/plan-redacted.txt   # exits 1 on a leak
"""

from __future__ import annotations

import argparse
import re
import sys

SUBSTITUTIONS: list[tuple[str, str]] = [
    # UUIDs first -- see module docstring.
    (r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", "<UUID>"),
    (r"\b\d{12}\b", "<ACCOUNT_NAME_ACCOUNT_ID>"),
    (r"(AKIA|ASIA)[A-Z0-9]{16}", "***"),
    (r'"Z[A-Z0-9]{10,}"', '"<ZONE_ID>"'),
    # by attribute name, for values with no recognisable shape
    (r'(zone_id|hosted_zone_id)(\s*)= "[^"]*"', r'\1\2= "<ZONE_ID>"'),
    (r'(pgp_key|encrypted_secret|encrypted_password|password)(\s*)= "[^"]*"', r'\1\2= "***"'),
    (r'(resource_record_value|validation_record_fqdns?)(\s*)= "[^"]*"', r'\1\2= "<VALIDATION>"'),
]

LEAK_SCAN = re.compile(
    r"\b\d{12}\b"
    r"|arn:aws:iam::\d"
    r"|AKIA|ASIA"
    r"|-----BEGIN"
    r"|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
    r'|"Z[A-Z0-9]{10,}"'
)


def redact(text: str) -> str:
    for pattern, replacement in SUBSTITUTIONS:
        text = re.sub(pattern, replacement, text)
    return text


def scan(text: str) -> list[tuple[int, str]]:
    return [(n, line) for n, line in enumerate(text.splitlines(), 1) if LEAK_SCAN.search(line)]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", help="plan excerpt to read")
    parser.add_argument("--scan", action="store_true",
                        help="only scan for leaks; exit 1 if any remain")
    args = parser.parse_args(argv)

    text = open(args.path, encoding="utf-8").read()

    if args.scan:
        leaks = scan(text)
        for n, line in leaks:
            print(f"{args.path}:{n}: {line.strip()}", file=sys.stderr)
        if leaks:
            print(f"{len(leaks)} unredacted line(s)", file=sys.stderr)
            return 1
        print("clean", file=sys.stderr)
        return 0

    out = redact(text)
    leaks = scan(out)
    for n, line in leaks:
        print(f"LEAK line {n}: {line.strip()}", file=sys.stderr)
    sys.stdout.write(out)
    return 1 if leaks else 0


if __name__ == "__main__":
    sys.exit(main())
