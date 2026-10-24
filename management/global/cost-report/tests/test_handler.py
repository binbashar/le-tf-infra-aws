import datetime

import pytest

import handler

# Every fixture holds the 8 days 2026-10-15 .. 2026-10-22 -- a 7-day baseline
# plus yesterday -- so the report runs as if "today" were 2026-10-23.
TODAY = "2026-10-23"


def run(result, **kwargs):
    kwargs.setdefault("length", 20)
    return handler.report_cost(result=result, today=TODAY, account_name="test-org", **kwargs)


def table_rows(buffer):
    """{name: (yesterday's cost, ∆$, ∆%)} for every row between the header and the footer."""
    rows = {}
    for line in buffer.splitlines()[1:]:
        if not line:
            break
        name, rest = line.split("$", 1)
        yday, usd, pct = rest.split()[:3]
        rows[name.strip()] = (float(yday.replace(",", "")), float(usd.replace(",", "")), pct)
    return rows


# --- window -----------------------------------------------------------------

def test_window_is_a_baseline_week_plus_yesterday():
    week_ago, yesterday, dates = handler.date_window(datetime.date(2026, 10, 23))
    assert week_ago == datetime.date(2026, 10, 15)
    assert yesterday == datetime.date(2026, 10, 22)
    assert dates == [f"2026-10-{d}" for d in range(15, 23)]


def test_window_crosses_month_boundary():
    _, yesterday, dates = handler.date_window(datetime.date(2026, 11, 3))
    assert yesterday == datetime.date(2026, 11, 2)
    assert dates[0] == "2026-10-26" and dates[-1] == "2026-11-02"


def test_query_uses_the_window_of_the_given_day(monkeypatch, load_fixture):
    queries = []

    class FakeCE:
        def get_cost_and_usage(self, **query):
            queries.append(query)
            return load_fixture("normal.json")

    monkeypatch.setattr(handler.boto3, "client", lambda service: FakeCE())
    handler.report_cost(today=TODAY, account_name="test-org")

    assert queries[0]["TimePeriod"] == {"Start": "2026-10-15", "End": "2026-10-23"}


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


# --- delta ------------------------------------------------------------------

@pytest.mark.parametrize("costs, expected", [
    ([5.0] * 7 + [5.5], (0.5, "+10%")),
    ([1.2] * 8, (0.0, "+0%")),
    ([3.0] * 7 + [0.0], (-3.0, "-100%")),
    ([0.0] * 7 + [0.8], (0.8, "new")),
    ([0.0] * 8, (0.0, "-")),
    # under $1: the old delta() reported 0% for any of these
    ([0.2] * 7 + [0.4], (0.2, "+100%")),
])
def test_delta_is_against_the_baseline_average(costs, expected):
    assert handler.delta(costs) == expected


def test_delta_never_prints_negative_zero():
    usd, _ = handler.delta([0.3001] * 7 + [0.3])
    assert f"{usd:+.2f}" == "+0.00"


# --- table ------------------------------------------------------------------

def test_rows_show_change_in_dollars_and_percent(load_fixture):
    rows = table_rows(run(load_fixture("normal.json"))[1])

    assert rows["Amazon Elastic Compute Cloud - Compute"] == (5.5, 0.5, "+10%")
    assert rows["Amazon Simple Storage Service"] == (1.8, 0.0, "+0%")
    assert rows["Amazon Bedrock"] == (0.8, 0.8, "new")
    assert rows["Amazon Route 53"] == (0.0, -0.07, "-100%")


def test_negligible_services_fold_into_other(load_fixture):
    rows = table_rows(run(load_fixture("normal.json"))[1])

    assert "Amazon GuardDuty" not in rows
    assert "Amazon Redshift" not in rows
    assert rows["Other (2 services)"][0] == 0.0


def test_movers_are_listed_outside_the_top_n(load_fixture):
    rows = table_rows(run(load_fixture("normal.json"), length=2)[1])

    # top 2 by cost, plus Bedrock (+0.80 >= 0.50), in cost order
    assert list(rows) == [
        "Amazon Elastic Compute Cloud - Compute",
        "Amazon Simple Storage Service",
        "Amazon Bedrock",
        "Other (5 services)",
        "Total",
    ]


def test_mover_threshold_is_configurable(load_fixture):
    rows = table_rows(run(load_fixture("normal.json"), length=2, mover_min_usd=1.0)[1])
    assert "Amazon Bedrock" not in rows


def test_service_dropped_to_zero_is_listed(load_fixture):
    _, buffer, data = run(load_fixture("drop_to_zero.json"), length=1)
    rows = table_rows(buffer)

    assert rows["Amazon OpenSearch Service"] == (0.0, -3.0, "-100%")
    assert rows["Total"] == (4.0, -3.0, "-43%")
    assert data["Amazon OpenSearch Service"][-1] == 0


def test_other_row_is_omitted_when_nothing_is_folded(load_fixture):
    rows = table_rows(run(load_fixture("drop_to_zero.json"))[1])
    assert not any(name.startswith("Other") for name in rows)


@pytest.mark.parametrize("length", [1, 2, 3, 20])
def test_rows_add_up_to_total(load_fixture, length):
    rows = table_rows(run(load_fixture("normal.json"), length=length)[1])
    total = rows.pop("Total")

    assert sum(r[0] for r in rows.values()) == pytest.approx(total[0], abs=0.01)
    assert total == (9.6, 1.27, "+15%")


def test_sparse_days_are_filled_with_zero(load_fixture):
    _, _, data = run(load_fixture("normal.json"))

    assert data["Amazon Route 53"] == [0.5] + [0] * 7
    assert data["AmazonCloudWatch"] == [0.3, 0.3, 0, 0.3, 0.3, 0.3, 0.3, 0.3]


def test_sparkline_covers_the_last_seven_days(load_fixture):
    buffer = run(load_fixture("normal.json"))[1]
    route53 = next(line for line in buffer.splitlines() if line.startswith("Amazon Route 53"))

    # the $0.50 fee on day one of the 8-day window is outside the sparkline
    assert route53.endswith("▁" * 7)


def test_empty_result_still_builds_a_report(load_fixture):
    summary, buffer, _ = run(load_fixture("empty.json"))

    assert "$0.00" in summary
    assert table_rows(buffer) == {"Total": (0.0, 0.0, "-")}


# --- summary and footer ---------------------------------------------------

def test_summary_marks_yesterday_partial_with_its_date(load_fixture):
    summary, buffer, _ = run(load_fixture("normal.json"))

    assert summary == "Yesterday's cost (2026-10-22, partial) for account test-org was $9.60"
    assert "Yday*" in buffer.splitlines()[0]
    assert buffer.rstrip().endswith(handler.partial_note)


def test_summary_names_the_report_scope(monkeypatch, load_fixture):
    monkeypatch.setenv("REPORT_SCOPE", "the AWS Organization")
    summary, _, _ = run(load_fixture("normal.json"))
    assert "for the AWS Organization (test-org) was $9.60" in summary


def test_footer_states_metric_exclusions_and_baseline(load_fixture):
    buffer = run(load_fixture("normal.json"))[1]

    assert "∆: yesterday vs. the average of the previous 7 days" in buffer
    assert "Unblended cost, excluding Credit, Refund, Upfront and Support records" in buffer


def test_footer_follows_the_cost_metric():
    assert handler.footer("AmortizedCost").splitlines()[1].startswith("Amortized cost, excluding")


def test_query_excludes_the_record_types_the_footer_names(monkeypatch, load_fixture):
    queries = []

    class FakeCE:
        def get_cost_and_usage(self, **query):
            queries.append(query)
            return load_fixture("empty.json")

    monkeypatch.setattr(handler.boto3, "client", lambda service: FakeCE())
    handler.report_cost(today=TODAY, account_name="test-org")

    excluded = queries[0]["Filter"]["Not"]["Dimensions"]["Values"]
    assert all(record_type in handler.footer("UnblendedCost") for record_type in excluded)


def test_credits_summary_is_dated_too(monkeypatch, load_fixture):
    monkeypatch.setenv("CREDITS_EXPIRE_DATE", "12/31/2026")
    monkeypatch.setenv("CREDITS_REMAINING_AS_OF", "10/01/2026")
    monkeypatch.setenv("CREDITS_REMAINING", "910")

    summary, _, _ = run(load_fixture("normal.json"))

    assert "(2026-10-22, partial)" in summary
    assert "of credit budget $10.00" in summary
