import datetime

import pytest

import handler

# Every fixture holds the 7 days 2026-10-16 .. 2026-10-22, so the report runs
# as if "today" were 2026-10-23.
TODAY = "2026-10-23"


def run(result, **kwargs):
    kwargs.setdefault("length", 20)
    return handler.report_cost(result=result, today=TODAY, account_name="test-org", **kwargs)


def table_rows(buffer):
    """{name: yesterday's cost} for every row between the header and the note."""
    rows = {}
    for line in buffer.splitlines()[1:]:
        if not line or line.startswith("*"):
            continue
        name, rest = line.split("$", 1)
        rows[name.strip()] = float(rest.split()[0].replace(",", ""))
    return rows


def test_window_is_the_seven_days_before_today():
    week_ago, yesterday, dates = handler.date_window(datetime.date(2026, 10, 23))
    assert week_ago == datetime.date(2026, 10, 16)
    assert yesterday == datetime.date(2026, 10, 22)
    assert dates == [f"2026-10-{d}" for d in range(16, 23)]


def test_window_crosses_month_boundary():
    _, yesterday, dates = handler.date_window(datetime.date(2026, 11, 3))
    assert yesterday == datetime.date(2026, 11, 2)
    assert dates[0] == "2026-10-27" and dates[-1] == "2026-11-02"


def test_query_uses_the_window_of_the_given_day(monkeypatch, load_fixture):
    queries = []

    class FakeCE:
        def get_cost_and_usage(self, **query):
            queries.append(query)
            return load_fixture("normal.json")

    monkeypatch.setattr(handler.boto3, "client", lambda service: FakeCE())
    handler.report_cost(today=TODAY, account_name="test-org")

    assert queries[0]["TimePeriod"] == {"Start": "2026-10-16", "End": "2026-10-23"}


def test_default_day_is_computed_per_call(monkeypatch, load_fixture):
    """Regression: the date used to be fixed at import, so a warm container reported a stale window."""
    seen = []

    class FakeCE:
        def get_cost_and_usage(self, **query):
            seen.append(query["TimePeriod"]["End"])
            return load_fixture("empty.json")

    class FakeDatetime(datetime.datetime):
        current = datetime.datetime(2026, 10, 23, 12, tzinfo=datetime.timezone.utc)

        @classmethod
        def now(cls, tz=None):
            return cls.current

    monkeypatch.setattr(handler.boto3, "client", lambda service: FakeCE())
    monkeypatch.setattr(handler.datetime, "datetime", FakeDatetime)

    handler.report_cost(account_name="test-org")
    FakeDatetime.current += datetime.timedelta(days=1)
    handler.report_cost(account_name="test-org")

    assert seen == ["2026-10-23", "2026-10-24"]


def test_summary_marks_yesterday_partial_with_its_date(load_fixture):
    summary, buffer, _ = run(load_fixture("normal.json"))

    assert "(2026-10-22, partial)" in summary
    assert "$8.80" in summary
    assert "Yday*" in buffer.splitlines()[0]
    assert buffer.rstrip().endswith(handler.partial_note)


def test_rows_add_up_to_total(load_fixture):
    _, buffer, data = run(load_fixture("normal.json"), length=2)
    rows = table_rows(buffer)
    total = rows.pop("Total")

    assert list(rows) == [
        "Amazon Elastic Compute Cloud - Compute",
        "Amazon Simple Storage Service",
        "Other",
    ]
    assert sum(rows.values()) == pytest.approx(total)
    assert data["total"] == pytest.approx(8.80)


def test_sparse_days_are_filled_with_zero(load_fixture):
    _, _, data = run(load_fixture("normal.json"))

    assert data["Amazon Route 53"] == [0.5, 0, 0, 0, 0, 0, 0]
    assert data["AmazonCloudWatch"] == [0.3, 0.3, 0, 0.3, 0.3, 0.3, 0.3]


def test_service_absent_yesterday_is_kept_at_zero(load_fixture):
    _, buffer, data = run(load_fixture("drop_to_zero.json"))

    assert data["Amazon OpenSearch Service"][-1] == 0
    assert table_rows(buffer)["Amazon OpenSearch Service"] == 0
    assert data["total"] == pytest.approx(4.0)


def test_empty_result_still_builds_a_report(load_fixture):
    summary, buffer, data = run(load_fixture("empty.json"))

    assert "$0.00" in summary
    assert table_rows(buffer) == {"Other": 0, "Total": 0}


def test_credits_summary_is_dated_too(monkeypatch, load_fixture):
    monkeypatch.setenv("CREDITS_EXPIRE_DATE", "12/31/2026")
    monkeypatch.setenv("CREDITS_REMAINING_AS_OF", "10/01/2026")
    monkeypatch.setenv("CREDITS_REMAINING", "910")

    summary, _, _ = run(load_fixture("normal.json"))

    assert "(2026-10-22, partial)" in summary
    assert "of credit budget $10.00" in summary
