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
    """Return (severity, days_left_to_end_of_standard_support)."""
    if status == "UNKNOWN":
        return "UNKNOWN", None
    if status == "UNSUPPORTED":
        return "UNSUPPORTED", None

    days = (end_standard - today).days if end_standard else None

    # A past end date wins over a lagging status field.
    if status == "EXTENDED_SUPPORT" or (days is not None and days < 0):
        return "EXTENDED", days
    if days is not None and days <= lead_days:
        return "SOON", days
    return "OK", days
