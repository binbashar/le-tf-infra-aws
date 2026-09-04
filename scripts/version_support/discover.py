"""Discover Kubernetes and database engine version pins in the OpenTofu tree.

Pure filesystem + HCL parsing. This module never calls AWS.
"""

from __future__ import annotations

import os


def is_disabled_layer(path: str) -> bool:
    """True when any path segment marks the layer disabled.

    Both suffix forms occur in this repo and the rule must match both:
    ``databases-mysql --`` (spaced) and ``databases-dynamodb--`` (attached).
    Matching on ``" --"`` would silently treat the attached form as active and
    hard-fail PRs on dormant infrastructure.
    """
    return any(
        segment.rstrip().endswith("--")
        for segment in path.replace("\\", "/").split("/")
        if segment
    )
