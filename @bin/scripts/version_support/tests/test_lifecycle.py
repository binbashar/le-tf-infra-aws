from datetime import date

import pytest

from version_support.lifecycle import classify

TODAY = date(2026, 9, 4)


@pytest.mark.parametrize(
    ("status", "end_standard", "expected_severity", "expected_days"),
    [
        ("STANDARD_SUPPORT", date(2027, 6, 1), "OK", 270),
        ("STANDARD_SUPPORT", date(2026, 11, 1), "SOON", 58),
        ("STANDARD_SUPPORT", date(2026, 12, 3), "SOON", 90),      # exactly at the line
        ("STANDARD_SUPPORT", date(2026, 12, 4), "OK", 91),        # one day past it
        ("EXTENDED_SUPPORT", date(2026, 1, 1), "EXTENDED", -246),
        ("UNSUPPORTED", None, "UNSUPPORTED", None),
        ("UNKNOWN", None, "UNKNOWN", None),
    ],
)
def test_classify_severity_boundaries(status, end_standard, expected_severity, expected_days):
    severity, days = classify(status, end_standard, today=TODAY)

    assert severity == expected_severity
    assert days == expected_days


def test_a_past_end_date_is_extended_even_if_status_lags():
    severity, _ = classify("STANDARD_SUPPORT", date(2026, 8, 1), today=TODAY)

    assert severity == "EXTENDED"


def test_lead_days_is_configurable():
    severity, _ = classify("STANDARD_SUPPORT", date(2027, 1, 1), today=TODAY, lead_days=180)

    assert severity == "SOON"


def test_a_healthy_status_with_no_date_is_unknown_not_ok():
    # An absent or unparseable endOfStandardSupportDate must never read as "fine".
    severity, days = classify("STANDARD_SUPPORT", None, today=TODAY)

    assert severity == "UNKNOWN"
    assert days is None


def test_a_bad_status_still_classifies_without_a_date():
    # EXTENDED/UNSUPPORTED are status-driven and must not be downgraded to UNKNOWN.
    assert classify("EXTENDED_SUPPORT", None, today=TODAY)[0] == "EXTENDED"
    assert classify("UNSUPPORTED", None, today=TODAY)[0] == "UNSUPPORTED"


from datetime import datetime, timedelta, timezone

from version_support.lifecycle import as_date

EAST = timezone(timedelta(hours=9))
WEST = timezone(timedelta(hours=-3))


@pytest.mark.parametrize(
    ("value", "expected", "label"),
    [
        (datetime(2026, 12, 1, 21, 0, tzinfo=WEST), date(2026, 12, 2), "west: naive reads a day EARLY"),
        (datetime(2026, 12, 2, 6, 0, tzinfo=EAST), date(2026, 12, 1), "east: naive reads a day LATE"),
        (datetime(2026, 12, 2, 0, 0, tzinfo=timezone.utc), date(2026, 12, 2), "already UTC"),
        (datetime(2026, 12, 2, 9, 0), date(2026, 12, 2), "naive: no zone to convert from"),
        (date(2026, 12, 2), date(2026, 12, 2), "plain date"),
        (None, None, "absent"),
        ("2026-12-02", None, "unparseable"),
    ],
)
def test_as_date_normalises_to_utc(value, expected, label):
    # botocore parses an AWS timestamp into tzlocal(), NOT UTC, so one API response
    # yields a different calendar day per machine: EKS 1.34's end of standard support
    # arrived as 2026-12-01 21:00-03:00 on a UTC-03 workstation and as 2026-12-02 on
    # the UTC CI runner, which is how this was found.
    assert as_date(value) == expected, label


def test_the_timezone_skew_cannot_downgrade_extended_to_soon():
    # Why the conversion is load-bearing rather than cosmetic. `today` is UTC (see
    # __main__), so an end date parsed east of UTC must be converted before the
    # subtraction: 2026-09-15 06:00+09:00 is 2026-09-14 in UTC, one day PAST the
    # cliff. Reading it as 2026-09-15 instead returns SOON with days_left 0 -- a
    # supported-looking verdict on a version already accruing the surcharge, which
    # is the exact failure this guardrail exists to prevent.
    end = as_date(datetime(2026, 9, 15, 6, 0, tzinfo=EAST))

    assert end == date(2026, 9, 14)
    assert classify("STANDARD_SUPPORT", end, today=date(2026, 9, 15)) == ("EXTENDED", -1)


from datetime import datetime

import boto3
from botocore.stub import Stubber

from version_support.lifecycle import eks_lifecycles, rds_lifecycle


def test_eks_lifecycles_maps_versions_to_support_state():
    client = boto3.client("eks", region_name="us-east-1")
    with Stubber(client) as stub:
        stub.add_response(
            "describe_cluster_versions",
            {
                "clusterVersions": [
                    {
                        "clusterVersion": "1.34",
                        "versionStatus": "STANDARD_SUPPORT",
                        "endOfStandardSupportDate": datetime(2027, 3, 23),
                        "endOfExtendedSupportDate": datetime(2028, 3, 23),
                    },
                    {
                        "clusterVersion": "1.28",
                        "versionStatus": "EXTENDED_SUPPORT",
                        "endOfStandardSupportDate": datetime(2024, 11, 26),
                        "endOfExtendedSupportDate": datetime(2025, 11, 26),
                    },
                ]
            },
            {"includeAll": True},
        )

        result = eks_lifecycles({"1.34", "1.28"}, client)

    assert result["1.34"] == ("STANDARD_SUPPORT", date(2027, 3, 23), date(2028, 3, 23))
    assert result["1.28"][0] == "EXTENDED_SUPPORT"


def test_eks_lifecycles_follows_pagination():
    # Now that this fetches the whole catalog instead of naming versions, a
    # truncated response is a real possibility -- and a dropped version would
    # surface as UNKNOWN rather than as an error.
    client = boto3.client("eks", region_name="us-east-1")
    with Stubber(client) as stub:
        stub.add_response(
            "describe_cluster_versions",
            {
                "clusterVersions": [
                    {
                        "clusterVersion": "1.34",
                        "versionStatus": "STANDARD_SUPPORT",
                        "endOfStandardSupportDate": datetime(2027, 3, 23),
                    }
                ],
                "nextToken": "page2",
            },
            {"includeAll": True},
        )
        stub.add_response(
            "describe_cluster_versions",
            {
                "clusterVersions": [
                    {
                        "clusterVersion": "1.28",
                        "versionStatus": "EXTENDED_SUPPORT",
                        "endOfStandardSupportDate": datetime(2024, 11, 26),
                    }
                ]
            },
            {"includeAll": True, "nextToken": "page2"},
        )

        result = eks_lifecycles({"1.34", "1.28"}, client)

    # Both pages contributed; the version on page 2 is not lost.
    assert set(result) == {"1.34", "1.28"}
    assert result["1.28"][0] == "EXTENDED_SUPPORT"


def test_eks_lifecycles_ignores_versions_it_was_not_asked_about():
    # The catalog returns every version; only the pinned ones belong in the map.
    client = boto3.client("eks", region_name="us-east-1")
    with Stubber(client) as stub:
        stub.add_response(
            "describe_cluster_versions",
            {
                "clusterVersions": [
                    {"clusterVersion": "1.34", "versionStatus": "STANDARD_SUPPORT"},
                    {"clusterVersion": "1.21", "versionStatus": "UNSUPPORTED"},
                ]
            },
            {"includeAll": True},
        )

        result = eks_lifecycles({"1.34"}, client)

    assert set(result) == {"1.34"}


def test_rds_lifecycle_derives_status_from_lifecycle_entries():
    client = boto3.client("rds", region_name="us-east-1")
    with Stubber(client) as stub:
        stub.add_response(
            "describe_db_major_engine_versions",
            {
                "DBMajorEngineVersions": [
                    {
                        "Engine": "aurora-mysql",
                        "MajorEngineVersion": "5.7",
                        "SupportedEngineLifecycles": [
                            {
                                "LifecycleSupportName": "open-source-rds-standard-support",
                                "LifecycleSupportStartDate": datetime(2021, 3, 1),
                                "LifecycleSupportEndDate": datetime(2024, 10, 31),
                            },
                            {
                                "LifecycleSupportName": "open-source-rds-extended-support",
                                "LifecycleSupportStartDate": datetime(2024, 11, 1),
                                "LifecycleSupportEndDate": datetime(2027, 10, 31),
                            },
                        ],
                    }
                ]
            },
            {"Engine": "aurora-mysql", "MajorEngineVersion": "5.7"},
        )

        status, end_standard, end_extended = rds_lifecycle(
            "aurora-mysql", "5.7", client, today=TODAY
        )

    assert status == "EXTENDED_SUPPORT"
    assert end_standard == date(2024, 10, 31)
    assert end_extended == date(2027, 10, 31)


def test_rds_lifecycle_returns_unknown_for_an_unlisted_version():
    client = boto3.client("rds", region_name="us-east-1")
    with Stubber(client) as stub:
        stub.add_response(
            "describe_db_major_engine_versions",
            {"DBMajorEngineVersions": []},
            {"Engine": "mysql", "MajorEngineVersion": "99.9"},
        )

        status, end_standard, _ = rds_lifecycle("mysql", "99.9", client, today=TODAY)

    assert status == "UNKNOWN"
    assert end_standard is None


from version_support.discover import Pin
from version_support.lifecycle import LookupUnavailable, evaluate

EKS_PIN = Pin(
    kind="eks",
    engine=None,
    version="1.28",
    major_version="1.28",
    layer="apps-devstg/us-east-1/k8s-eks-demoapps/cluster",
    active=True,
    source="cluster/variables.tf:9 (var.cluster_version)",
)


def test_evaluate_turns_pins_into_findings():
    eks = boto3.client("eks", region_name="us-east-1")
    rds = boto3.client("rds", region_name="us-east-1")
    with Stubber(eks) as stub:
        stub.add_response(
            "describe_cluster_versions",
            {
                "clusterVersions": [
                    {
                        "clusterVersion": "1.28",
                        "versionStatus": "EXTENDED_SUPPORT",
                        "endOfStandardSupportDate": datetime(2024, 11, 26),
                        "endOfExtendedSupportDate": datetime(2025, 11, 26),
                    }
                ]
            },
            {"includeAll": True},
        )

        findings = evaluate([EKS_PIN], eks_client=eks, rds_client=rds, today=TODAY)

    assert len(findings) == 1
    assert findings[0].severity == "EXTENDED"
    assert findings[0].pin is EKS_PIN


def test_an_unresolvable_pin_is_unknown_without_calling_aws():
    unresolved = Pin(
        kind="eks",
        engine=None,
        version=None,
        major_version=None,
        layer="apps-devstg/us-east-1/k8s-eks-demoapps/cluster",
        active=True,
        source="cluster/main.tf:5 (unresolved)",
    )
    eks = boto3.client("eks", region_name="us-east-1")
    rds = boto3.client("rds", region_name="us-east-1")

    # No Stubber responses queued: any AWS call would raise.
    with Stubber(eks), Stubber(rds):
        findings = evaluate([unresolved], eks_client=eks, rds_client=rds, today=TODAY)

    assert findings[0].severity == "UNKNOWN"


def test_an_aws_failure_raises_lookup_unavailable():
    eks = boto3.client("eks", region_name="us-east-1")
    rds = boto3.client("rds", region_name="us-east-1")
    with Stubber(eks) as stub:
        stub.add_client_error("describe_cluster_versions", service_error_code="AccessDenied")

        with pytest.raises(LookupUnavailable):
            evaluate([EKS_PIN], eks_client=eks, rds_client=rds, today=TODAY)
