"""Keyed digest of the changes an OpenTofu JSON plan would apply.

The apply stage re-plans and refuses to apply unless its plan has the same digest
as the plan that was reviewed. The digest covers values, so a value that changed
between review and apply is caught; it is an HMAC because the result artifact is
public and a plain hash of a low-entropy value could be brute-forced.
"""

from __future__ import annotations

import hashlib
import hmac
import json
import re
from typing import Any

DIGEST_VERSION = "v1"
DIGEST = re.compile(r"hmac-sha256:v1:[0-9a-f]{64}\Z")
MIN_KEY_BYTES = 32

CHANGE_FIELDS = (
    "actions",
    "before",
    "after",
    "after_unknown",
    "before_sensitive",
    "after_sensitive",
    "replace_paths",
)


def _change(change: dict) -> dict:
    return {field: change.get(field) for field in CHANGE_FIELDS}


def canonical_changes(plan: dict) -> dict[str, Any]:
    """Return what an apply of this plan would do, independent of key order.

    Drift and no-op resources are left out: they are not applied. Data source
    reads are kept, since their results can feed managed resources.
    """
    resources = sorted(
        (
            {"address": item.get("address"), **_change(item.get("change") or {})}
            for item in plan.get("resource_changes") or []
            if (item.get("change") or {}).get("actions") != ["no-op"]
        ),
        key=lambda resource: str(resource["address"]),
    )
    outputs = {
        name: _change(output or {})
        for name, output in sorted((plan.get("output_changes") or {}).items())
        if (output or {}).get("actions") != ["no-op"]
    }
    return {"version": DIGEST_VERSION, "resource_changes": resources, "output_changes": outputs}


def plan_digest(plan: dict, key: str) -> str:
    secret = key.encode("utf-8")
    if len(secret) < MIN_KEY_BYTES:
        raise ValueError(f"digest key must be at least {MIN_KEY_BYTES} bytes")
    payload = json.dumps(
        canonical_changes(plan), sort_keys=True, separators=(",", ":"), ensure_ascii=True
    ).encode("utf-8")
    return f"hmac-sha256:{DIGEST_VERSION}:{hmac.new(secret, payload, hashlib.sha256).hexdigest()}"


def digests_match(left: str, right: str) -> bool:
    return bool(DIGEST.fullmatch(left) and DIGEST.fullmatch(right)) and hmac.compare_digest(
        left, right
    )
