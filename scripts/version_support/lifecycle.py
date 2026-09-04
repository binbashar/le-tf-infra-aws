"""Classify version pins against AWS support lifecycles.

Pure logic plus AWS lookups. This module never reads the filesystem.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime

from version_support.discover import Pin

DEFAULT_LEAD_DAYS = 90

# Severities that fail a PR when found on an active layer.
BLOCKING = frozenset({"EXTENDED", "UNSUPPORTED"})


@dataclass(frozen=True)
class Finding:
    pin: Pin
    status: str  # STANDARD_SUPPORT | EXTENDED_SUPPORT | UNSUPPORTED | UNKNOWN
    end_standard: date | None
    end_extended: date | None
    days_left: int | None
    severity: str


def as_date(value) -> date | None:
    """Normalise a boto3 timestamp to a date."""
    if value is None:
        return None
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    return None


def classify(
    status: str,
    end_standard: date | None,
    today: date,
    lead_days: int = DEFAULT_LEAD_DAYS,
) -> tuple[str, int | None]:
    """Classify one version against its support lifecycle.

    Returns ``(severity, days_left)`` where ``days_left`` counts down to the end of
    standard support and is NEGATIVE once that date has passed.

    Severities, in order of urgency:
      OK          - in standard support, further out than ``lead_days``
      SOON        - in standard support, within ``lead_days`` of the cliff
      EXTENDED    - past end of standard support: the surcharge is billing now
      UNSUPPORTED - AWS reports the version unsupported outright
      UNKNOWN     - no usable data; never treated as safe
    """
    if status == "UNKNOWN":
        return "UNKNOWN", None
    if status == "UNSUPPORTED":
        return "UNSUPPORTED", None

    days = (end_standard - today).days if end_standard else None

    # A past end date wins over a lagging status field: AWS's status can trail the
    # transition, but the surcharge is billing either way.
    if status == "EXTENDED_SUPPORT" or (days is not None and days < 0):
        return "EXTENDED", days

    # No date and no explicit bad status means we do not know -- and an absence of
    # information must never read as "fine". UNKNOWN warns without failing a PR.
    if days is None:
        return "UNKNOWN", None

    if days <= lead_days:
        return "SOON", days
    return "OK", days
