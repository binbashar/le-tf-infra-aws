"""Classify version pins against AWS support lifecycles.

Pure logic plus AWS lookups. This module never reads the filesystem.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime

from botocore.exceptions import BotoCoreError, ClientError

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


# Neither lookup below paginates. Each request names specific items -- an explicit
# list of EKS versions, or one RDS engine+major -- so a truncated response is not a
# realistic outcome. Worth revisiting if either call ever grows to an unbounded
# listing: a dropped result would surface as UNKNOWN, not as an error.

# Verified against the botocore service model - these are lowercase-hyphenated,
# not the SCREAMING_CASE the EKS enum uses.
_RDS_STANDARD = "open-source-rds-standard-support"
_RDS_EXTENDED = "open-source-rds-extended-support"


def eks_lifecycles(versions: set[str], client) -> dict[str, tuple]:
    """{version: (status, end_standard, end_extended)} for the given k8s versions.

    ``includeAll=True`` is required: without it AWS omits versions that have
    already left standard support, which are exactly the ones we care about.

    Raises botocore.exceptions.ClientError / BotoCoreError on AWS failure -- callers
    decide how to handle it; these functions never swallow one.
    """
    if not versions:
        return {}

    response = client.describe_cluster_versions(
        clusterVersions=sorted(versions), includeAll=True
    )
    return {
        item["clusterVersion"]: (
            item.get("versionStatus", "UNKNOWN"),
            as_date(item.get("endOfStandardSupportDate")),
            as_date(item.get("endOfExtendedSupportDate")),
        )
        for item in response.get("clusterVersions", [])
    }


def rds_lifecycle(engine: str, major: str, client, today: date) -> tuple:
    """(status, end_standard, end_extended) for one RDS/Aurora major version.

    RDS exposes no status field, so it is derived from the lifecycle windows.

    Raises botocore.exceptions.ClientError / BotoCoreError on AWS failure -- callers
    decide how to handle it; these functions never swallow one.
    """
    response = client.describe_db_major_engine_versions(
        Engine=engine, MajorEngineVersion=major
    )
    entries = response.get("DBMajorEngineVersions", [])
    if not entries:
        return "UNKNOWN", None, None

    # The request filters on exactly one Engine + MajorEngineVersion, so AWS returns
    # zero or one entry. Extras, if AWS ever returned any, are deliberately ignored.
    lifecycles = entries[0].get("SupportedEngineLifecycles", [])
    by_name = {item.get("LifecycleSupportName"): item for item in lifecycles}
    end_standard = as_date(
        (by_name.get(_RDS_STANDARD) or {}).get("LifecycleSupportEndDate")
    )
    end_extended = as_date(
        (by_name.get(_RDS_EXTENDED) or {}).get("LifecycleSupportEndDate")
    )

    if end_standard is None:
        return "UNKNOWN", None, end_extended
    # Strict > on purpose: on the exact end date the current window is still open.
    # Consistent with classify(), where days == 0 is SOON rather than EXTENDED.
    if end_extended is not None and today > end_extended:
        return "UNSUPPORTED", end_standard, end_extended
    if today > end_standard:
        return "EXTENDED_SUPPORT", end_standard, end_extended
    return "STANDARD_SUPPORT", end_standard, end_extended


class LookupUnavailable(RuntimeError):
    """AWS could not be reached or refused the call.

    Raised rather than swallowed so callers must decide explicitly. A guardrail
    that silently reports 'all clear' when it could not run is worse than none.
    """


def evaluate(pins, *, eks_client, rds_client, today: date, lead_days: int = DEFAULT_LEAD_DAYS):
    """Turn pins into findings. Raises LookupUnavailable if AWS cannot be reached."""
    findings: list[Finding] = []

    resolvable = [pin for pin in pins if pin.major_version]
    eks_versions = {pin.major_version for pin in resolvable if pin.kind == "eks"}

    try:
        eks_map = eks_lifecycles(eks_versions, eks_client)
        rds_map = {}
        for pin in resolvable:
            if pin.kind != "rds":
                continue
            key = (pin.engine, pin.major_version)
            if key not in rds_map:
                rds_map[key] = rds_lifecycle(pin.engine, pin.major_version, rds_client, today)
    except (BotoCoreError, ClientError) as exc:
        raise LookupUnavailable(str(exc)) from exc

    for pin in pins:
        if not pin.major_version:
            findings.append(Finding(pin, "UNKNOWN", None, None, None, "UNKNOWN"))
            continue

        if pin.kind == "eks":
            status, end_standard, end_extended = eks_map.get(
                pin.major_version, ("UNKNOWN", None, None)
            )
        else:
            status, end_standard, end_extended = rds_map[(pin.engine, pin.major_version)]

        severity, days = classify(status, end_standard, today, lead_days)
        findings.append(
            Finding(pin, status, end_standard, end_extended, days, severity)
        )

    return findings
