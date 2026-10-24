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


def fake_ce(load_fixture, queries, grouped="normal.json"):
    """A Cost Explorer stand-in: the grouped fixture for the table query, monthly.json for the month summary."""
    class FakeCE:
        def get_cost_and_usage(self, **query):
            queries.append(query)
            return load_fixture(grouped if "GroupBy" in query else "monthly.json")
    return lambda service: FakeCE()


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
    monkeypatch.setattr(handler.boto3, "client", fake_ce(load_fixture, queries))
    handler.report_cost(today=TODAY, account_name="test-org")

    assert queries[0]["TimePeriod"] == {"Start": "2026-10-15", "End": "2026-10-23"}


def test_default_day_is_computed_per_call(monkeypatch, load_fixture):
    """Regression: the date used to be fixed at import, so a warm container reported a stale window."""
    queries = []

    class FakeDatetime(datetime.datetime):
        current = datetime.datetime(2026, 10, 23, 12, tzinfo=datetime.timezone.utc)

        @classmethod
        def now(cls, tz=None):
            return cls.current

    monkeypatch.setattr(handler.boto3, "client", fake_ce(load_fixture, queries, grouped="empty.json"))
    monkeypatch.setattr(handler.datetime, "datetime", FakeDatetime)

    handler.report_cost(account_name="test-org")
    FakeDatetime.current += datetime.timedelta(days=1)
    handler.report_cost(account_name="test-org")

    assert [q["TimePeriod"]["End"] for q in queries if "GroupBy" in q] == ["2026-10-23", "2026-10-24"]


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

    assert rows["EC2 - Compute"] == (5.5, 0.5, "+10%")
    assert rows["S3"] == (1.8, 0.0, "+0%")
    assert rows["Bedrock"] == (0.8, 0.8, "new")
    assert rows["Route 53"] == (0.0, -0.07, "-100%")


def test_negligible_services_fold_into_other(load_fixture):
    rows = table_rows(run(load_fixture("normal.json"))[1])

    assert "GuardDuty" not in rows
    assert "Redshift" not in rows
    assert rows["Other (2 services)"][0] == 0.0


def test_movers_are_listed_outside_the_top_n(load_fixture):
    rows = table_rows(run(load_fixture("normal.json"), length=2)[1])

    # top 2 by cost, plus Bedrock (+0.80 >= 0.50), in cost order
    assert list(rows) == [
        "EC2 - Compute",
        "S3",
        "Bedrock",
        "Other (5 services)",
        "Total",
    ]


def test_mover_threshold_uses_the_unrounded_change():
    # a row outside the top 1 that moved +0.4996: rounds to +0.50, yet is under the threshold
    result = {"ResultsByTime": [
        {"TimePeriod": {"Start": f"2026-10-{d}"}, "Groups": [
            {"Keys": ["Big"], "Metrics": {"UnblendedCost": {"Amount": "9"}}},
            {"Keys": ["Mover"], "Metrics": {"UnblendedCost": {"Amount": "0.4996" if d == 22 else "0"}}},
        ]}
        for d in range(15, 23)
    ]}
    rows = table_rows(run(result, length=1)[1])

    assert "Mover" not in rows
    assert handler.delta([0.0] * 7 + [0.4996])[0] == 0.5  # what the old check compared


def test_mover_threshold_is_configurable(load_fixture):
    rows = table_rows(run(load_fixture("normal.json"), length=2, mover_min_usd=1.0)[1])
    assert "Bedrock" not in rows


def test_service_dropped_to_zero_is_listed(load_fixture):
    _, buffer, data = run(load_fixture("drop_to_zero.json"), length=1)
    rows = table_rows(buffer)

    assert rows["OpenSearch Service"] == (0.0, -3.0, "-100%")
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
    route53 = next(line for line in buffer.splitlines() if line.startswith("Route 53"))

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
    monkeypatch.setattr(handler.boto3, "client", fake_ce(load_fixture, queries, grouped="empty.json"))
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


# --- names ------------------------------------------------------------------

@pytest.mark.parametrize("name, short", [
    ("Amazon Elastic Compute Cloud - Compute", "EC2 - Compute"),
    ("Amazon Simple Storage Service", "S3"),
    ("AmazonCloudWatch", "CloudWatch"),
    ("AWS Config", "Config"),
    ("Amazon Route 53", "Route 53"),
    ("Claude Haiku 5.5 (Amazon Bedrock Edition)", "Claude Haiku 5.5 (Bedrock)"),
    ("EC2 - Other", "EC2 - Other"),
    ("Kiro", "Kiro"),
])
def test_short_name(name, short):
    assert handler.short_name(name) == short


def test_full_names_are_kept_when_shortening_would_collide():
    result = {"ResultsByTime": [
        {"TimePeriod": {"Start": f"2026-10-{d}"}, "Groups": [
            {"Keys": [key], "Metrics": {"UnblendedCost": {"Amount": "1"}}}
            for key in ("Amazon Widget", "AWS Widget")
        ]}
        for d in range(15, 23)
    ]}
    rows = table_rows(run(result)[1])
    assert {"Amazon Widget", "AWS Widget"} <= set(rows)


def test_linked_account_names_are_not_shortened(load_fixture):
    report = handler.build_report(group_by="LINKED_ACCOUNT", length=20, result=load_fixture("normal.json"),
                                  today=TODAY, account_name="test-org")
    assert "Amazon Simple Storage Service" in [r["name"] for r in report["rows"]]


# --- Block Kit --------------------------------------------------------------

def blocks_for(fixture, **kwargs):
    kwargs.setdefault("length", 20)
    report = handler.build_report(result=fixture, today=TODAY, account_name="test-org", **kwargs)
    return report, handler.render_blocks(report)


def cell_text(cell):
    if cell["type"] == "raw_text":
        return cell["text"]
    return cell["elements"][0]["elements"][0]["text"]


def test_blocks_layout(load_fixture):
    report, payload = blocks_for(load_fixture("normal.json"))

    assert payload["text"] == report["summary"]
    assert [b["type"] for b in payload["blocks"]] == ["header", "section", "table", "context"]

    header = payload["blocks"][0]["text"]
    assert header == {"type": "plain_text", "text": "AWS cost · 2026-10-22 (partial)"}
    assert len(header["text"]) <= 150

    section = payload["blocks"][1]["text"]["text"]
    assert section.startswith("*$9.60* yesterday · ∆ +$1.27 (+15%) vs. the 7-day average")
    assert "For account test-org" in section


def test_blocks_table_matches_the_text_table(load_fixture):
    report, payload = blocks_for(load_fixture("normal.json"), length=2)
    table = payload["blocks"][2]

    header, *rows = table["rows"]
    assert [cell_text(c) for c in header] == ["Service", "Yday*", "∆$", "∆%", "Last 7d"]
    assert [[cell_text(c) for c in r][:4] for r in rows] == [
        ["EC2 - Compute", "$5.50", "+$0.50", "+10%"],
        ["S3", "$1.80", "+$0.00", "+0%"],
        ["Bedrock", "$0.80", "+$0.80", "new"],
        ["Other (5 services)", "$1.50", "-$0.03", "-2%"],
        ["Total", "$9.60", "+$1.27", "+15%"],
    ]
    assert all(len(r) == len(header) for r in rows)
    assert len(table["rows"]) <= 100


def test_blocks_table_bolds_header_other_and_total(load_fixture):
    _, payload = blocks_for(load_fixture("normal.json"), length=2)
    first_cells = [r[0]["type"] for r in payload["blocks"][2]["rows"]]
    assert first_cells == ["rich_text", "raw_text", "raw_text", "raw_text", "rich_text", "rich_text"]


def test_blocks_footer_is_the_text_footer(load_fixture):
    report, payload = blocks_for(load_fixture("normal.json"))
    context = payload["blocks"][3]["elements"]
    assert [e["text"] for e in context] == report["footer"].splitlines()
    assert all(e["type"] == "plain_text" for e in context)


def test_blocks_carry_the_credit_line(monkeypatch, load_fixture):
    monkeypatch.setenv("CREDITS_EXPIRE_DATE", "12/31/2026")
    monkeypatch.setenv("CREDITS_REMAINING_AS_OF", "10/01/2026")
    monkeypatch.setenv("CREDITS_REMAINING", "910")
    _, payload = blocks_for(load_fixture("normal.json"))
    assert "of the credit budget $10.00 for the day" in payload["blocks"][1]["text"]["text"]


def test_blocks_for_an_empty_result(load_fixture):
    _, payload = blocks_for(load_fixture("empty.json"))
    rows = payload["blocks"][2]["rows"]
    assert [cell_text(c) for c in rows[-1]][:4] == ["Total", "$0.00", "+$0.00", "-"]


@pytest.mark.parametrize("usd, sign, text", [
    (1234.5, False, "$1,234.50"),
    (1.27, True, "+$1.27"),
    (-0.4, True, "-$0.40"),
    (0.0, True, "+$0.00"),
])
def test_money(usd, sign, text):
    assert handler.money(usd, sign=sign) == text


# --- publishing -------------------------------------------------------------

def test_slack_gets_the_blocks_payload(monkeypatch):
    sent = []
    monkeypatch.setattr(handler, "post_json", lambda url, payload: sent.append(payload) or (200, "ok"))

    handler.publish_slack("https://hook", "summary", "table", {"text": "summary", "blocks": []})

    assert sent == [{"text": "summary", "blocks": []}]


def test_slack_falls_back_to_text_when_blocks_are_rejected(monkeypatch):
    sent = []

    def post(url, payload):
        sent.append(payload)
        return (400, "invalid_blocks") if "blocks" in payload else (200, "ok")

    monkeypatch.setattr(handler, "post_json", post)
    handler.publish_slack("https://hook", "summary", "table", {"text": "summary", "blocks": []})

    assert len(sent) == 2
    assert sent[1] == {"text": "summary\n\n```\ntable\n```"}


# --- month summary ------------------------------------------------------------

def test_monthly_query_is_ungrouped_from_the_start_of_last_month(monkeypatch, load_fixture):
    queries = []
    monkeypatch.setattr(handler.boto3, "client", fake_ce(load_fixture, queries))
    handler.build_report(today=TODAY, account_name="test-org")

    table_query, monthly_query = queries
    assert "GroupBy" not in monthly_query
    assert monthly_query["TimePeriod"] == {"Start": "2026-09-01", "End": "2026-10-23"}
    assert monthly_query["Filter"] == table_query["Filter"]
    assert monthly_query["Metrics"] == table_query["Metrics"]


@pytest.mark.parametrize("yesterday, expected", [
    ("2026-10-22", ("2026-09-01", "2026-09-22", "2026-10-01")),
    ("2026-03-31", ("2026-02-01", "2026-02-28", "2026-03-01")),   # capped at February's length
    ("2026-10-31", ("2026-09-01", "2026-09-30", "2026-10-01")),   # report run on Nov 1st
    ("2027-01-15", ("2026-12-01", "2026-12-15", "2027-01-01")),   # across a year
])
def test_month_window(yesterday, expected):
    window = handler.month_window(datetime.date.fromisoformat(yesterday))
    assert tuple(day.isoformat() for day in window) == expected


def test_month_summary(load_fixture):
    report = handler.build_report(result=load_fixture("normal.json"), monthly_result=load_fixture("monthly.json"),
                                  today=TODAY, account_name="test-org")
    month = report["month"]

    # Oct 1-22 at $10/day vs Sep 1-22 at $8/day; 9 days left at the $10 average
    assert month["month_to_date"] == pytest.approx(220)
    assert month["last_month_to_date"] == pytest.approx(176)
    assert month["pct"] == "+25%"
    assert month["pace"] == pytest.approx(310)
    assert report["month_lines"] == [
        "October to date: $220.00 · same point in September $176.00 (+25%) · on pace for $310.00"]


def test_month_pace_ignores_a_one_off_charge_in_the_last_week():
    totals = {f"2026-10-{d:02d}": 10.0 for d in range(1, 23)}
    totals["2026-10-18"] = 635.0   # a monthly Marketplace fee, inside the 7 days before yesterday
    month = handler.month_summary(totals, datetime.date(2026, 10, 22))

    # 9 days left at the $10 median; the mean ($99/day) would add ~$800
    assert month["pace"] == pytest.approx(sum(totals.values()) + 9 * 10)


def test_month_summary_on_the_last_day_has_nothing_left_to_pace():
    totals = {f"2026-10-{d:02d}": 1.0 for d in range(1, 32)}
    month = handler.month_summary(totals, datetime.date(2026, 10, 31))
    assert month["pace"] == month["month_to_date"] == 31


def test_month_summary_left_out_without_monthly_data(load_fixture):
    report = handler.build_report(result=load_fixture("normal.json"), today=TODAY, account_name="test-org")
    assert report["month"] is None and report["month_lines"] == []
    assert handler.render_text(report).startswith("Service")


# --- budget -------------------------------------------------------------------

BUDGET = {
    "BudgetName": "budget-MONTHLY-test",
    "BudgetLimit": {"Amount": "750.0", "Unit": "USD"},
    "CalculatedSpend": {"ActualSpend": {"Amount": "874.644", "Unit": "USD"},
                        "ForecastedSpend": {"Amount": "952.91", "Unit": "USD"}},
    "CostTypes": {"IncludeTax": True, "IncludeSupport": True, "IncludeUpfront": True,
                  "IncludeOtherSubscription": True, "IncludeCredit": False},
}


def test_budget_line_uses_aws_budgets_figures_and_says_what_they_include():
    assert handler.budget_line(BUDGET) == (
        "AWS Budget (incl. tax, support, upfront, Marketplace; excl. credits): "
        "$874.64 of $750.00 (117%) · forecast $952.91")


def test_budget_line_without_forecast_or_extras():
    budget = {"BudgetLimit": {"Amount": "100"}, "CalculatedSpend": {"ActualSpend": {"Amount": "40"}},
              "CostTypes": {"IncludeCredit": True}}
    assert handler.budget_line(budget) == "AWS Budget (usage only; incl. credits): $40.00 of $100.00 (40%)"


def test_month_lines_in_text_and_blocks(load_fixture):
    report = handler.build_report(result=load_fixture("normal.json"), monthly_result=load_fixture("monthly.json"),
                                  budget=BUDGET, today=TODAY, account_name="test-org", length=20)

    lines = report["month_lines"]
    assert len(lines) == 2 and lines[1].startswith("AWS Budget")
    assert handler.render_text(report).startswith(lines[0] + "\n" + lines[1] + "\n\n")
    section = handler.render_blocks(report)["blocks"][1]["text"]["text"]
    assert section.endswith("\n" + lines[0] + "\n" + lines[1])


def test_budget_is_read_from_aws_budgets(monkeypatch):
    calls = []

    class Fake:
        def get_caller_identity(self):
            return {"Account": "000000000000"}

        def describe_budget(self, **kwargs):
            calls.append(kwargs)
            return {"Budget": BUDGET}

    monkeypatch.setattr(handler.boto3, "client", lambda service: Fake())
    assert handler.get_budget("budget-MONTHLY-test") == BUDGET
    assert calls == [{"AccountId": "000000000000", "BudgetName": "budget-MONTHLY-test"}]


def test_budget_failure_does_not_stop_the_report(monkeypatch, load_fixture):
    def broken(service):
        raise RuntimeError("AccessDenied")

    monkeypatch.setattr(handler.boto3, "client", broken)
    report = handler.build_report(result=load_fixture("normal.json"), monthly_result=load_fixture("monthly.json"),
                                  budget_name="budget-MONTHLY-test", today=TODAY, account_name="test-org")
    assert len(report["month_lines"]) == 1
