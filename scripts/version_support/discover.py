"""Discover Kubernetes and database engine version pins in the OpenTofu tree.

Pure filesystem + HCL parsing. This module never calls AWS.
"""

from __future__ import annotations

import glob
import os
import re

import hcl2
from hcl2.utils import SerializationOptions

# python-hcl2 v8 keeps surrounding quotes on keys and string values and injects
# __is_block__ / __comments__ metadata keys into the parsed dicts. These options
# give plain Python values.
OPTS = SerializationOptions(
    with_comments=False,
    explicit_blocks=False,
    strip_string_quotes=True,
)


def is_disabled_layer(path: str) -> bool:
    """True when any path segment marks the layer disabled.

    Both suffix forms occur in this repo and the rule must match both:
    ``databases-mysql --`` (spaced) and ``databases-dynamodb--`` (attached).
    Matching on ``" --"`` would silently treat the attached form as active and
    hard-fail PRs on dormant infrastructure.

    Trailing whitespace in a segment is stripped before the suffix check, so
    ``databases-mysql -- `` is detected too -- the ``.rstrip()`` is load-bearing,
    not decorative.
    """
    return any(
        segment.rstrip().endswith("--")
        for segment in path.replace("\\", "/").split("/")
        if segment
    )


def line_of(path: str, key: str) -> int | None:
    """1-indexed line where `key` is assigned or declared, or None.

    python-hcl2 gives no line numbers under OPTS (``with_meta`` is ignored when
    ``explicit_blocks`` is off), so findings get their line from a text scan.
    """
    patterns = (
        re.compile(rf"^\s*{re.escape(key)}\s*="),
        re.compile(rf'^\s*variable\s+"{re.escape(key)}"'),
    )
    try:
        with open(path, encoding="utf-8") as handle:
            for number, line in enumerate(handle, 1):
                if any(pattern.match(line) for pattern in patterns):
                    return number
    except OSError:
        return None
    return None


def load_layer(layer_dir: str) -> tuple[dict[str, dict], list[str]]:
    """Parse every ``*.tf`` in one layer. Returns (docs_by_path, parse_errors).

    A file that fails to parse is recorded and skipped; the scan continues so one
    malformed file never blinds the whole run.
    """
    docs: dict[str, dict] = {}
    errors: list[str] = []
    for path in sorted(glob.glob(os.path.join(layer_dir, "*.tf"))):
        try:
            with open(path, encoding="utf-8") as handle:
                docs[path] = hcl2.load(handle, serialization_options=OPTS)
        except Exception as exc:  # noqa: BLE001 - any parse failure is reportable
            errors.append(f"{path}: {exc}")
    return docs, errors
