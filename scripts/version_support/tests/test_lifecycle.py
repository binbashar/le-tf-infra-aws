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
