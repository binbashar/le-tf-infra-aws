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

    # one day before the table's 8: drops are judged on the day before yesterday
    assert queries[0]["TimePeriod"] == {"Start": "2026-10-14", "End": "2026-10-23"}


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


def table_of(payload):
    return next(b for b in payload["blocks"] if b["type"] == "table")


def texts(payload):
    """The mrkdwn text of every section, in order."""
    return [b["text"]["text"] for b in payload["blocks"] if b["type"] == "section"]


def cell_text(cell):
    if cell["type"] == "raw_text":
        return cell["text"]
    return cell["elements"][0]["elements"][0]["text"]


def test_blocks_layout(load_fixture):
    report, payload = blocks_for(load_fixture("normal.json"))

    assert payload["text"] == report["summary"]
    assert [b["type"] for b in payload["blocks"]] == ["header", "section", "section", "table", "context"]

    header = payload["blocks"][0]["text"]
    assert header == {"type": "plain_text", "emoji": True, "text": "AWS cost · 2026-10-22 (partial)"}
    assert len(header["text"]) <= 150

    assert texts(payload) == ["*Yesterday*\n*$9.60* · ∆ +$1.27 (+15%) vs. the 7-day average", "*Top services*"]


def test_blocks_table_matches_the_text_table(load_fixture):
    report, payload = blocks_for(load_fixture("normal.json"), length=2)
    table = table_of(payload)

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
    first_cells = [r[0]["type"] for r in table_of(payload)["rows"]]
    assert first_cells == ["rich_text", "raw_text", "raw_text", "raw_text", "rich_text", "rich_text"]


def test_blocks_footer_spells_out_the_method_without_a_help_link(load_fixture):
    report, payload = blocks_for(load_fixture("normal.json"))
    first, *rest = payload["blocks"][-1]["elements"]
    assert first["text"] == "Yday* is partial: Cost Explorer may still add charges · ∆: vs. the 7-day average"
    # the method, minus the partial note the first line already gives
    assert [e["text"] for e in rest] == report["footer"].splitlines()[:-1]


def test_blocks_footer_links_the_help_instead(load_fixture):
    report = handler.build_report(result=load_fixture("normal.json"), today=TODAY, account_name="test-org")
    footer = handler.render_blocks(report, help_url="https://example.com/readme#how")["blocks"][-1]["elements"]
    assert len(footer) == 1
    assert footer[0]["text"].endswith(" · <https://example.com/readme#how|How to read this report>")


def test_blocks_carry_the_credit_line(monkeypatch, load_fixture):
    monkeypatch.setenv("CREDITS_EXPIRE_DATE", "12/31/2026")
    monkeypatch.setenv("CREDITS_REMAINING_AS_OF", "10/01/2026")
    monkeypatch.setenv("CREDITS_REMAINING", "910")
    _, payload = blocks_for(load_fixture("normal.json"))
    assert "of the credit budget $10.00 for the day" in texts(payload)[0]


def test_blocks_for_an_empty_result(load_fixture):
    _, payload = blocks_for(load_fixture("empty.json"))
    rows = table_of(payload)["rows"]
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
    month = texts(handler.render_blocks(report))[1]
    assert month.startswith("*October*\n")
    assert month.splitlines()[2] == handler.budget_short_line(BUDGET)


def test_budget_is_read_from_aws_budgets(monkeypatch):
    calls = []

    class Fake:
        def get_caller_identity(self):
            return {"Account": "000000000000"}

        def describe_budget(self, **kwargs):
            calls.append(kwargs)
            return {"Budget": BUDGET}

    monkeypatch.setattr(handler.boto3, "client", lambda service, **kwargs: Fake())
    assert handler.get_budget("budget-MONTHLY-test") == BUDGET
    assert calls == [{"AccountId": "000000000000", "BudgetName": "budget-MONTHLY-test"}]


def test_budget_failure_does_not_stop_the_report(monkeypatch, load_fixture):
    def broken(service, **kwargs):
        raise RuntimeError("AccessDenied")

    monkeypatch.setattr(handler.boto3, "client", broken)
    report = handler.build_report(result=load_fixture("normal.json"), monthly_result=load_fixture("monthly.json"),
                                  budget_name="budget-MONTHLY-test", today=TODAY, account_name="test-org")
    assert len(report["month_lines"]) == 1


# --- alerts (D1) --------------------------------------------------------------

YESTERDAY = datetime.date(2026, 10, 22)


def history_result(series):
    """A GetCostAndUsage response for the 9 days 2026-10-14 .. 2026-10-22 from {name: [9 costs]}."""
    days = [datetime.date(2026, 10, 14) + datetime.timedelta(days=d) for d in range(9)]
    return {"ResultsByTime": [
        {"TimePeriod": {"Start": day.isoformat()}, "Groups": [
            {"Keys": [name], "Metrics": {"UnblendedCost": {"Amount": str(costs[i])}}}
            for name, costs in series.items() if costs[i]
        ]}
        for i, day in enumerate(days)
    ]}


def alerts(history, min_usd=1.0, min_pct=30.0):
    return [(a["direction"], a["day"].isoformat(), round(a["usd"], 2), a["pct"])
            for a in handler.find_alerts("X", history, min_usd, min_pct, YESTERDAY)]


def test_rise_on_yesterday_alerts():
    assert alerts([2.0] * 8 + [3.5]) == [("up", "2026-10-22", 1.5, "+75%")]


@pytest.mark.parametrize("history", [
    [2.0] * 8 + [2.9],    # +$0.90: under $1
    [10.0] * 8 + [12.5],  # +25%: under 30%
])
def test_rise_needs_both_thresholds(history):
    assert alerts(history) == []


def test_new_cost_alerts_on_dollars_alone():
    assert alerts([0.0] * 8 + [1.2]) == [("up", "2026-10-22", 1.2, "new")]


def test_partial_yesterday_never_raises_a_drop():
    # yesterday reads $0 because it is partial; the day before was normal
    assert alerts([3.0] * 8 + [0.0]) == []


def test_drop_alerts_on_the_day_before_yesterday():
    assert alerts([3.0] * 7 + [0.0, 0.0]) == [("down", "2026-10-21", -3.0, "-100%")]


def test_one_off_monthly_charge_alerts_once_and_never_as_a_drop():
    # a $625 Marketplace fee: alerts the day it lands...
    assert alerts([0.0] * 8 + [625.0]) == [("up", "2026-10-22", 625.0, "new")]
    # ...and its absence afterwards is not a drop, while the mean would say -$89
    assert alerts([0.0] * 4 + [625.0] + [0.0] * 4) == []


def test_thresholds_are_configurable():
    assert alerts([2.0] * 8 + [2.9], min_usd=0.5) == [("up", "2026-10-22", 0.9, "+45%")]


def test_report_alerts_use_short_names_and_sort_by_size():
    result = history_result({
        "Amazon Simple Storage Service": [2.0] * 8 + [3.5],
        "Amazon OpenSearch Service": [3.0] * 7 + [0.0, 0.0],
        "AWS Key Management Service": [1.0] * 9,
    })
    report = handler.build_report(result=result, today=TODAY, account_name="test-org", length=20, alert_min_usd=1.0)
    assert [(a["name"], a["direction"]) for a in report["alerts"]] == [("OpenSearch Service", "down"), ("S3", "up")]


def test_alerts_are_off_without_a_threshold(load_fixture):
    report = handler.build_report(result=load_fixture("normal.json"), today=TODAY, account_name="test-org")
    assert report["alerts"] is None


def alerting_report(**kwargs):
    result = history_result({"Amazon Simple Storage Service": [2.0] * 8 + [3.5], "Kiro": [0.65] * 9})
    return handler.build_report(result=result, today=TODAY, account_name="test-org", length=20,
                                alert_min_usd=1.0, **kwargs)


def quiet_report(**kwargs):
    return handler.build_report(result=history_result({"Kiro": [0.65] * 9}), monthly_result=kwargs.pop("monthly", None),
                                today=TODAY, account_name="test-org", length=20, alert_min_usd=1.0, **kwargs)


def test_full_report_shows_the_verdict_and_alerts():
    report = alerting_report()
    payload = handler.render_blocks(report, mention="<!here>")

    assert payload["blocks"][0]["text"]["text"] == ":warning: AWS cost · 2026-10-22 (partial) · 1 alert"
    assert texts(payload)[1] == (
        "<!here>\n*Alerts*\n• S3: $3.50 yesterday (partial), +$1.50 (+75%) vs. a typical day ($2.00)")
    assert payload["text"].startswith(":warning: 1 alert · Yesterday's cost")
    assert [b["type"] for b in payload["blocks"]] == ["header", "section", "section", "section", "table", "context"]

    text = handler.render_text(report)
    assert text.startswith(":warning: 1 alert\n• S3: $3.50 yesterday (partial)")


def test_quiet_full_report_says_no_alerts_and_skips_the_alert_section():
    payload = handler.render_blocks(quiet_report())
    assert payload["blocks"][0]["text"]["text"].startswith(":white_check_mark: AWS cost")
    assert payload["blocks"][0]["text"]["text"].endswith("· no alerts")
    assert [b["type"] for b in payload["blocks"]] == ["header", "section", "section", "table", "context"]
    assert "*Alerts*" not in "".join(texts(payload))


def test_footer_states_the_alert_rule():
    footer = alerting_report()["footer"]
    assert ("Alerts: a move of $1.00 and 30% vs. a typical day (median of the 7 days before); "
            "rises on yesterday, drops on the day before") in footer


def test_compact_line(load_fixture):
    assert handler.compact_line(quiet_report()) == (
        ":white_check_mark: AWS cost 2026-10-22 (partial): $0.65 (+0% vs. the 7-day average) · no alerts")
    with_month = quiet_report(monthly=load_fixture("monthly.json"))
    assert " · October to date $220.00 · on pace for $310.00 · no alerts" in handler.compact_line(with_month)


def test_compact_line_on_a_day_with_alerts_states_the_real_verdict():
    line = handler.compact_line(alerting_report())
    assert line.startswith(":warning: AWS cost 2026-10-22 (partial)")
    assert line.endswith(" · 1 alert")


def test_compact_line_without_alerts_configured_claims_nothing(load_fixture):
    report = handler.build_report(result=load_fixture("normal.json"), today=TODAY, account_name="test-org")
    line = handler.compact_line(report)
    assert line.startswith("AWS cost 2026-10-22 (partial)")
    assert "alert" not in line


def test_compact_blocks_are_one_section():
    payload = handler.render_compact_blocks(quiet_report())
    assert payload["text"] == handler.compact_line(quiet_report())
    assert [b["type"] for b in payload["blocks"]] == ["section"]


# TODAY (2026-10-23) is a Friday; 2026-10-26 a Monday
@pytest.mark.parametrize("build, requested, daily_mode, weekday, expected", [
    (quiet_report, None, "compact", 0, "compact"),
    (alerting_report, None, "compact", 0, "full"),       # alerts
    (quiet_report, None, "compact", 4, "full"),          # weekly full-report day
    (quiet_report, None, "full", 0, "full"),             # DAILY_MODE=full
    (quiet_report, "full", "compact", 0, "full"),        # {"mode": "full"}
    (alerting_report, "compact", "compact", 0, "compact"),
])
def test_report_mode(build, requested, daily_mode, weekday, expected):
    assert handler.report_mode(build(), requested, daily_mode, weekday) == expected


def test_report_mode_is_full_when_alerts_are_off(load_fixture):
    report = handler.build_report(result=load_fixture("normal.json"), today=TODAY, account_name="test-org")
    assert handler.report_mode(report) == "full"


def test_as_text_without_a_table():
    assert handler.as_text("one line", None) == "one line"
    assert handler.as_text("summary", "table") == "summary\n\n```\ntable\n```"


def test_lambda_posts_the_compact_line_on_a_quiet_day(monkeypatch, load_fixture):
    sent, report = [], quiet_report()
    monkeypatch.setattr(handler, "build_report", lambda **kwargs: report)
    monkeypatch.setattr(handler, "post_json", lambda url, payload: sent.append(payload) or (200, "ok"))
    monkeypatch.setenv("SLACK_WEBHOOK_URL", "https://hook")
    monkeypatch.setenv("DAILY_MODE", "compact")
    monkeypatch.setenv("FULL_REPORT_WEEKDAY", "0")

    handler.lambda_handler({}, None)

    assert sent == [handler.render_compact_blocks(report)]


def test_lambda_sends_the_full_report_by_default(monkeypatch):
    sent, report = [], quiet_report()
    monkeypatch.setattr(handler, "build_report", lambda **kwargs: report)
    monkeypatch.setattr(handler, "post_json", lambda url, payload: sent.append(payload) or (200, "ok"))
    monkeypatch.setenv("SLACK_WEBHOOK_URL", "https://hook")

    handler.lambda_handler({}, None)

    assert sent == [handler.render_blocks(report)]


def test_lambda_posts_the_full_report_when_asked(monkeypatch):
    sent, report = [], quiet_report()
    monkeypatch.setattr(handler, "build_report", lambda **kwargs: report)
    monkeypatch.setattr(handler, "post_json", lambda url, payload: sent.append(payload) or (200, "ok"))
    monkeypatch.setenv("SLACK_WEBHOOK_URL", "https://hook")

    handler.lambda_handler({"mode": "full"}, None)

    assert sent[0]["blocks"][0]["type"] == "header"


# --- Cost Anomaly Detection (D2) ----------------------------------------------

def anomaly(service, start, impact, end="same", feedback=None, region=None, account=None, account_id=None, usage=None):
    cause = {k: v for k, v in (("Service", service), ("Region", region), ("LinkedAccountName", account),
                               ("LinkedAccount", account_id), ("UsageType", usage)) if v}
    found = {
        "AnomalyId": f"id-{service}-{start}",
        "AnomalyStartDate": f"{start}T00:00:00Z",
        "DimensionValue": service,
        "RootCauses": [cause],
        "Impact": {"MaxImpact": impact, "TotalImpact": impact},
        "MonitorArn": "arn:aws:ce::000000000000:anomalymonitor/test",
    }
    if end is not None:
        found["AnomalyEndDate"] = f"{start if end == 'same' else end}T00:00:00Z"
    if feedback:
        found["Feedback"] = feedback
    return found


ANOMALIES = [
    anomaly("Amazon Bedrock", "2026-10-21", 8.27, region="us-east-1", usage="USE1-Model_Large-input-tokens"),
    anomaly("AWS End User Messaging", "2026-10-15", 1.89, region="us-east-1", account="example-dev"),
    anomaly("Amazon QuickSight", "2026-10-12", 7.11, feedback="PLANNED_ACTIVITY"),
]


def test_open_anomalies_skip_the_ones_with_feedback_and_sort_by_impact():
    found = handler.open_anomalies(ANOMALIES)
    assert [(a["name"], a["impact"]) for a in found] == [("Bedrock", 8.27), ("End User Messaging", 1.89)]


@pytest.mark.parametrize("found, line", [
    (anomaly("Amazon Bedrock", "2026-10-21", 8.27, region="us-east-1", usage="USE1-Model_Large-input-tokens"),
     "Bedrock · 2026-10-21 · +$8.27 · `us-east-1 · USE1-Model_Large-input-tokens`"),
    (anomaly("AWS End User Messaging", "2026-10-15", 1.89, end="2026-10-17", account="example-dev"),
     "End User Messaging · 2026-10-15 → 2026-10-17 · +$1.89 · `example-dev`"),
    (anomaly("Amazon Cognito", "2026-10-20", 2.0, end=None, account_id="000000000000"),
     "Cognito · since 2026-10-20 · +$2.00 · `000000000000`"),
    (anomaly("Kiro", "2026-10-20", 3.0),
     "Kiro · 2026-10-20 · +$3.00"),
])
def test_anomaly_line(found, line):
    assert handler.anomaly_line(handler.open_anomalies([found])[0]) == line


def test_anomalies_are_read_since_the_window_with_the_impact_floor(monkeypatch, load_fixture):
    requests = []

    class FakeCE:
        def get_anomalies(self, **request):
            requests.append(dict(request))
            if "NextPageToken" not in request:
                return {"Anomalies": ANOMALIES[:1], "NextPageToken": "page-2"}
            return {"Anomalies": ANOMALIES[1:]}

    monkeypatch.setattr(handler.boto3, "client", lambda service, **kwargs: FakeCE())
    report = handler.build_report(result=load_fixture("normal.json"), today=TODAY, account_name="test-org",
                                  alert_min_usd=1.0, anomaly_days=14)

    assert requests[0] == {
        "DateInterval": {"StartDate": "2026-10-09", "EndDate": "2026-10-23"},
        "TotalImpact": {"NumericOperator": "GREATER_THAN_OR_EQUAL", "StartValue": 1.0},
    }
    assert requests[1]["NextPageToken"] == "page-2"
    assert [a["name"] for a in report["anomalies"]] == ["Bedrock", "End User Messaging"]


def test_anomaly_read_failure_does_not_stop_the_report(monkeypatch, load_fixture):
    def broken(service, **kwargs):
        raise RuntimeError("AccessDenied")

    monkeypatch.setattr(handler.boto3, "client", broken)
    report = handler.build_report(result=load_fixture("normal.json"), today=TODAY, account_name="test-org",
                                  alert_min_usd=1.0, anomaly_days=14)
    assert report["anomalies"] is None
    assert "Anomalies:" not in report["footer"]


def test_anomalies_off_by_default(load_fixture):
    report = handler.build_report(result=load_fixture("normal.json"), today=TODAY, account_name="test-org")
    assert report["anomalies"] is None


def anomalous_report(alerting=False, anomalies=ANOMALIES):
    build = alerting_report if alerting else quiet_report
    return build(anomaly_days=14, anomalies_result=anomalies)


@pytest.mark.parametrize("alerting, anomalies, status", [
    (False, [], ":white_check_mark: no alerts"),
    (False, ANOMALIES[:1], ":warning: 1 anomaly"),
    (False, ANOMALIES, ":warning: 2 anomalies"),
    (True, ANOMALIES, ":warning: 1 alert, 2 anomalies"),
])
def test_verdict_counts_alerts_and_anomalies(alerting, anomalies, status):
    assert " ".join(handler.verdict(anomalous_report(alerting, anomalies))) == status


def test_verdict_from_anomalies_alone_when_the_alert_rule_is_off(load_fixture):
    report = handler.build_report(result=load_fixture("normal.json"), today=TODAY, account_name="test-org",
                                  anomaly_days=14, anomalies_result=ANOMALIES)
    assert handler.has_verdict(report)
    assert handler.verdict(report) == (":warning:", "2 anomalies")


def test_anomalies_in_blocks_after_the_alerts_with_one_mention():
    payload = handler.render_blocks(anomalous_report(alerting=True), mention="<!here>")
    blocks = payload["blocks"]

    assert blocks[0]["text"]["text"].endswith("· 1 alert, 2 anomalies")
    assert [b["type"] for b in blocks] == ["header", "section", "section", "section", "section", "table", "context"]
    assert texts(payload)[1].startswith("<!here>\n*Alerts*\n• S3:")
    assert texts(payload)[2] == (
        "*Anomalies* · 2 open, no feedback yet\n"
        "• Bedrock · 2026-10-21 · +$8.27 · `us-east-1 · USE1-Model_Large-input-tokens`\n"
        "• End User Messaging · 2026-10-15 · +$1.89 · `us-east-1 · example-dev`\n"
        "Give feedback in Cost Explorer › Anomaly detection to clear them.")


def test_threaded_report_points_to_the_anomalies_in_the_thread():
    report = anomalous_report(alerting=True)
    main = handler.render_blocks(report, threaded=True)
    assert texts(main)[2] == "*Anomalies* · 2 open, no feedback yet · details in the thread :thread:"
    assert "More in the thread" in main["blocks"][-1]["elements"][0]["text"]

    thread = handler.render_thread_blocks(report)
    assert texts(thread)[0].startswith("*Anomalies* · 2 open, no feedback yet\n• Bedrock")
    assert thread["text"] == "Details · 2026-10-22 (partial): 2 anomalies"


def test_mention_goes_on_the_anomalies_when_there_are_no_alerts():
    payload = handler.render_blocks(anomalous_report(), mention="<!here>")
    assert texts(payload)[1].startswith("<!here>\n*Anomalies* · 2 open")
    threaded = handler.render_blocks(anomalous_report(), mention="<!here>", threaded=True)
    assert texts(threaded)[1].startswith("<!here>\n*Anomalies* · 2 open")


def test_anomalies_in_text():
    text = handler.render_text(anomalous_report())
    assert text.startswith(":warning: 2 anomalies\n\nCost Anomaly Detection: 2 open, no feedback yet\n• Bedrock")


def test_footer_states_the_anomaly_rule():
    assert ("Anomalies: Cost Anomaly Detection, without feedback, ended in the last 14 days, "
            "impact of at least $1.00") in anomalous_report()["footer"]


def test_anomalies_force_the_full_report_in_compact_mode():
    assert handler.report_mode(anomalous_report(anomalies=[]), None, "compact", 0) == "compact"
    assert handler.report_mode(anomalous_report(), None, "compact", 0) == "full"


def test_optional_calls_fail_fast(monkeypatch):
    """Budget and anomaly reads must give up well inside the Lambda timeout, not after botocore's 60 s."""
    configs = {}

    class Fake:
        def get_caller_identity(self):
            return {"Account": "000000000000"}

        def describe_budget(self, **kwargs):
            return {"Budget": BUDGET}

        def get_anomalies(self, **kwargs):
            return {"Anomalies": []}

    def client(service, config=None):
        configs[service] = config
        return Fake()

    monkeypatch.setattr(handler.boto3, "client", client)
    handler.get_budget("budget-MONTHLY-test")
    handler.get_anomalies(datetime.date(2026, 10, 9), datetime.date(2026, 10, 23), 1.0)

    assert set(configs) == {"sts", "budgets", "ce"}
    for config in configs.values():
        assert config is handler.optional_call_config
    worst = (handler.optional_call_config.connect_timeout + handler.optional_call_config.read_timeout) \
        * handler.optional_call_config.retries["total_max_attempts"]
    assert worst * 3 < 60 - 15   # three optional calls, plus the report's own requests and the post


def test_verdict_with_only_anomaly_detection_on_says_no_anomalies(load_fixture):
    report = handler.build_report(result=load_fixture("normal.json"), today=TODAY, account_name="test-org",
                                  anomaly_days=14, anomalies_result=[])
    assert handler.verdict(report) == (":white_check_mark:", "no anomalies")


# --- drill-down (D3) ----------------------------------------------------------

DATES = [(datetime.date(2026, 10, 14) + datetime.timedelta(days=d)).isoformat() for d in range(9)]


def breakdown_page(series, token=None, names=None):
    """A GetCostAndUsage page grouped by (LINKED_ACCOUNT, USAGE_TYPE) from {(account, usage): [9 costs]}."""
    page = {"ResultsByTime": [
        {"TimePeriod": {"Start": day}, "Groups": [
            {"Keys": list(key), "Metrics": {"UnblendedCost": {"Amount": str(costs[i])}}}
            for key, costs in series.items() if costs[i]
        ]}
        for i, day in enumerate(DATES)
    ], "DimensionValueAttributes": [
        {"Value": account, "Attributes": {"description": name}} for account, name in (names or {}).items()
    ]}
    if token:
        page["NextPageToken"] = token
    return page


S3_RISE = {
    ("000000000001", "USE1-TimedStorage-ByteHrs"): [1.0] * 8 + [1.0],     # flat
    ("000000000002", "USE1-Requests-Tier1"): [0.5] * 8 + [1.8],           # +1.30
    ("000000000002", "USE1-DataTransfer-Out-Bytes"): [0.5] * 8 + [0.7],   # +0.20
    ("000000000003", "USE1-Requests-Tier2"): [0.0] * 8 + [0.05],          # +0.05
}


def test_contributors_follow_the_alert_direction_and_rule():
    breakdown = {key: dict(zip(DATES, costs)) for key, costs in S3_RISE.items()}
    found = handler.contributors(breakdown, DATES, "up")
    assert [(c["account"], c["usage"], round(c["usd"], 2)) for c in found] == [
        ("000000000002", "USE1-Requests-Tier1", 1.3),
        ("000000000002", "USE1-DataTransfer-Out-Bytes", 0.2),
    ]
    # nothing dropped on the day before yesterday
    assert handler.contributors(breakdown, DATES, "down") == []


def test_contributors_of_a_drop_use_the_day_before_yesterday():
    breakdown = {("a", "gone"): dict(zip(DATES, [3.0] * 7 + [0.0, 0.0])),
                 ("a", "partial-yesterday-only"): dict(zip(DATES, [2.0] * 8 + [0.0]))}
    found = handler.contributors(breakdown, DATES, "down")
    assert [(c["usage"], c["usd"]) for c in found] == [("gone", -3.0)]


def fake_drilldown(monkeypatch, pages_by_service, calls):
    class FakeCE:
        def get_cost_and_usage(self, **request):
            service = request["Filter"]["And"][1]["Dimensions"]["Values"][0]
            calls.append((service, request))
            pages = pages_by_service[service]
            return pages[1] if "NextPageToken" in request else pages[0]

    monkeypatch.setattr(handler.boto3, "client", lambda service, **kwargs: FakeCE())


def drilled_report(**kwargs):
    result = history_result({
        "Amazon Simple Storage Service": [2.0] * 8 + [3.6],                   # +1.60 up
        "Amazon OpenSearch Service": [3.0] * 7 + [0.0, 0.0],                  # -3.00 down
        "Kiro": [0.65] * 9,
    })
    kwargs.setdefault("drilldown_max", 3)
    return handler.build_report(result=result, today=TODAY, account_name="test-org", length=20,
                                alert_min_usd=1.0, **kwargs)


def test_alerts_are_broken_down_with_one_request_each(monkeypatch):
    calls = []
    fake_drilldown(monkeypatch, {
        "Amazon Simple Storage Service": [breakdown_page(S3_RISE, names={"000000000002": "example-dev"})],
        "Amazon OpenSearch Service": [breakdown_page({("000000000001", "USE1-ES:Instance"): [3.0] * 7 + [0.0, 0.0]})],
    }, calls)

    report = drilled_report()

    service, request = calls[0]
    assert request["TimePeriod"] == {"Start": "2026-10-14", "End": "2026-10-23"}
    assert request["GroupBy"] == [{"Type": "DIMENSION", "Key": "LINKED_ACCOUNT"},
                                  {"Type": "DIMENSION", "Key": "USAGE_TYPE"}]
    assert request["Filter"]["And"][0] == {"Not": {"Dimensions": {"Key": "RECORD_TYPE",
                                                                  "Values": handler.excluded_record_types}}}
    assert [c[0] for c in calls] == ["Amazon OpenSearch Service", "Amazon Simple Storage Service"]

    by_name = {a["name"]: a["breakdown"] for a in report["alerts"]}
    assert [(c["account"], c["usage"]) for c in by_name["S3"]] == [
        ("example-dev", "USE1-Requests-Tier1"), ("example-dev", "USE1-DataTransfer-Out-Bytes")]
    assert [(c["account"], c["usd"]) for c in by_name["OpenSearch Service"]] == [("000000000001", -3.0)]


def test_breakdown_follows_pagination(monkeypatch):
    calls = []
    half = dict(list(S3_RISE.items())[:2])
    rest = dict(list(S3_RISE.items())[2:])
    fake_drilldown(monkeypatch, {"Amazon Simple Storage Service": [breakdown_page(half, token="p2"), breakdown_page(rest)],
                                 "Amazon OpenSearch Service": [breakdown_page({})]}, calls)
    report = drilled_report()
    s3 = next(a for a in report["alerts"] if a["name"] == "S3")
    assert len(s3["breakdown"]) == 2
    assert [c[1].get("NextPageToken") for c in calls if c[0] == "Amazon Simple Storage Service"] == [None, "p2"]


def test_only_the_largest_alerts_are_broken_down(monkeypatch):
    calls = []
    fake_drilldown(monkeypatch, {"Amazon OpenSearch Service": [breakdown_page({})]}, calls)
    report = drilled_report(drilldown_max=1)
    assert [c[0] for c in calls] == ["Amazon OpenSearch Service"]   # -3.00 beats +1.60
    assert next(a for a in report["alerts"] if a["name"] == "S3")["breakdown"] is None


def test_no_breakdown_started_after_the_deadline(monkeypatch):
    calls = []
    fake_drilldown(monkeypatch, {}, calls)
    report = drilled_report(deadline=handler.time.monotonic() - 1)
    assert calls == []
    assert all(a["breakdown"] is None for a in report["alerts"])


def test_failed_breakdown_leaves_the_alert_without_one(monkeypatch):
    def broken(service, **kwargs):
        raise RuntimeError("Throttling")

    monkeypatch.setattr(handler.boto3, "client", broken)
    report = drilled_report()
    assert len(report["alerts"]) == 2
    assert all(a["breakdown"] is None for a in report["alerts"])


def test_breakdown_uses_the_fail_fast_config(monkeypatch):
    configs = []

    class FakeCE:
        def get_cost_and_usage(self, **request):
            return breakdown_page({})

    monkeypatch.setattr(handler.boto3, "client", lambda service, config=None: configs.append(config) or FakeCE())
    drilled_report()
    assert configs and all(c is handler.optional_call_config for c in configs)


def test_no_breakdown_by_default(monkeypatch):
    calls = []
    fake_drilldown(monkeypatch, {}, calls)
    report = drilled_report(drilldown_max=0)
    assert calls == []


def test_breakdown_in_blocks_and_text(monkeypatch):
    fake_drilldown(monkeypatch, {
        "Amazon Simple Storage Service": [breakdown_page(S3_RISE, names={"000000000002": "example_dev"})],
        "Amazon OpenSearch Service": [breakdown_page({})],
    }, [])
    report = drilled_report()

    listing = texts(handler.render_blocks(report))[1]
    assert "• S3: $3.60 yesterday (partial), +$1.60 (+80%) vs. a typical day ($2.00)\n" \
           "    ↳ `example_dev · USE1-Requests-Tier1`: +$1.30\n" \
           "    ↳ `example_dev · USE1-DataTransfer-Out-Bytes`: +$0.20" in listing

    # threaded: the alert stays, its breakdown moves to the thread
    assert "↳" not in texts(handler.render_blocks(report, threaded=True))[1]
    assert texts(handler.render_thread_blocks(report))[0] == (
        "*Alert breakdown*\n• S3: +$1.60\n"
        "    ↳ `example_dev · USE1-Requests-Tier1`: +$1.30\n"
        "    ↳ `example_dev · USE1-DataTransfer-Out-Bytes`: +$0.20")

    text = handler.render_text(report)
    assert "    ↳ example_dev · USE1-Requests-Tier1: +$1.30\n" in text
    assert "`" not in text.split("Service")[0]


def test_lambda_sets_the_deadline_from_the_remaining_time(monkeypatch):
    seen, report = {}, quiet_report()

    def build(**kwargs):
        seen.update(kwargs)
        return report

    class Context:
        def get_remaining_time_in_millis(self):
            return 60_000

    monkeypatch.setattr(handler, "build_report", build)
    monkeypatch.setattr(handler.time, "monotonic", lambda: 1000.0)
    handler.lambda_handler({}, Context())

    assert seen["deadline"] == 1000.0 + 60 - 20
    assert seen["drilldown_max"] == 3


def test_contributors_skip_moves_against_the_alert():
    # a rise where one usage type fell by more than the others rose
    breakdown = {("a", "rose"): dict(zip(DATES, [1.0] * 8 + [3.0])),
                 ("a", "fell"): dict(zip(DATES, [5.0] * 8 + [0.5]))}
    assert [c["usage"] for c in handler.contributors(breakdown, DATES, "up")] == ["rose"]
    assert [c["usage"] for c in handler.contributors(breakdown, DATES, "down")] == []


# --- limits (CodeRabbit review of D3) -----------------------------------------

def test_sections_split_between_items_within_slacks_limit():
    items = ["x" * 1000] * 5
    blocks = handler.sections(items)
    texts = [b["text"]["text"] for b in blocks]
    assert [t.count("x" * 1000) for t in texts] == [2, 2, 1]
    assert all(len(t) <= handler.section_max_chars for t in texts)


def test_sections_put_the_mention_on_the_first_block_only():
    texts = [b["text"]["text"] for b in handler.sections(["a" * 2000, "b" * 2000], mention="<!here>")]
    assert texts[0].startswith("<!here>\n") and not texts[1].startswith("<!here>")


def test_sections_cut_an_item_too_long_on_its_own():
    texts = [b["text"]["text"] for b in handler.sections(["y" * 5000], mention="<!here>")]
    assert len(texts) == 1 and len(texts[0]) == handler.section_max_chars


def test_sections_of_nothing():
    assert handler.sections([], mention="<!here>") == []


def test_many_anomalies_stay_within_slacks_limits():
    many = [anomaly(f"Service {i:03d}", "2026-10-20", 2.0 + i, region="us-east-1",
                    usage="USE1-" + "Long_Usage_Type_" * 6 + str(i)) for i in range(80)]
    payload = handler.render_blocks(anomalous_report(alerting=True, anomalies=many), mention="<!here>")
    sections = [b for b in payload["blocks"] if b["type"] == "section"]
    assert len(sections) > 3
    assert all(len(b["text"]["text"]) <= handler.section_max_chars for b in sections)
    assert sum(b["text"]["text"].count("<!here>") for b in sections) == 1
    assert sum(b["text"]["text"].count("• Service ") for b in sections) == 80
    assert len(payload["blocks"]) <= 50


def test_breakdown_pagination_stops_at_the_deadline(monkeypatch):
    calls, clock = [], {"now": 0.0}

    class FakeCE:
        def get_cost_and_usage(self, **request):
            calls.append(request)
            clock["now"] += 30   # a slow page
            return breakdown_page({}, token="more")

    monkeypatch.setattr(handler.boto3, "client", lambda service, **kwargs: FakeCE())
    monkeypatch.setattr(handler.time, "monotonic", lambda: clock["now"])

    assert handler.get_breakdown("S", datetime.date(2026, 10, 14), datetime.date(2026, 10, 23),
                                 "UnblendedCost", deadline=20.0) is None
    assert len(calls) == 1


def test_breakdown_gives_up_past_the_page_cap(monkeypatch):
    calls = []

    class FakeCE:
        def get_cost_and_usage(self, **request):
            calls.append(request)
            return breakdown_page(S3_RISE, token="more")

    monkeypatch.setattr(handler.boto3, "client", lambda service, **kwargs: FakeCE())
    assert handler.get_breakdown("S", datetime.date(2026, 10, 14), datetime.date(2026, 10, 23),
                                 "UnblendedCost") is None
    assert len(calls) == handler.breakdown_max_pages


# --- cost by account (E) ------------------------------------------------------

def accounts_report(load_fixture, **kwargs):
    return handler.build_report(result=load_fixture("normal.json"), today=TODAY, account_name="test-org",
                                show_accounts=True, accounts_result=load_fixture("accounts.json"), **kwargs)


def test_account_rows_by_name_most_expensive_first(load_fixture):
    rows = accounts_report(load_fixture)["accounts"]
    assert [(r["name"], r["kind"]) for r in rows] == [
        ("example-shared", "item"), ("example-apps", "item"), ("000000000003", "item"),
        ("Other (1 account)", "other"), ("Total", "total")]
    shared = rows[0]
    assert (shared["yday"], shared["usd"], shared["pct"]) == (4.5, 1.5, "+50%")


def test_account_dropped_to_zero_is_listed_with_its_id(load_fixture):
    # no name in DimensionValueAttributes: the ID stands in
    dropped = accounts_report(load_fixture)["accounts"][2]
    assert (dropped["name"], dropped["yday"], dropped["pct"]) == ("000000000003", 0.0, "-100%")


def test_account_rows_add_up_to_total(load_fixture):
    rows = accounts_report(load_fixture)["accounts"]
    assert sum(r["yday"] for r in rows[:-1]) == pytest.approx(rows[-1]["yday"])
    assert rows[-1]["yday"] == pytest.approx(4.5 + 2 + 0.001)


def test_accounts_are_off_by_default(load_fixture):
    report = handler.build_report(result=load_fixture("normal.json"), today=TODAY, account_name="test-org")
    assert report["accounts"] is None


def test_accounts_are_skipped_when_the_table_already_groups_by_account(load_fixture):
    assert accounts_report(load_fixture, group_by="LINKED_ACCOUNT")["accounts"] is None


def test_accounts_query_covers_the_table_window(monkeypatch, load_fixture):
    queries = []

    class FakeCE:
        def get_cost_and_usage(self, **query):
            queries.append(query)
            return load_fixture("accounts.json")

    monkeypatch.setattr(handler.boto3, "client", lambda service, **kwargs: FakeCE())
    handler.build_report(result=load_fixture("normal.json"), today=TODAY, account_name="test-org", show_accounts=True)

    assert len(queries) == 1
    assert queries[0]["TimePeriod"] == {"Start": "2026-10-15", "End": TODAY}
    assert queries[0]["GroupBy"] == [{"Type": "DIMENSION", "Key": "LINKED_ACCOUNT"}]
    assert queries[0]["Filter"]["Not"]["Dimensions"]["Values"] == handler.excluded_record_types


def test_accounts_failure_does_not_stop_the_report(monkeypatch, load_fixture):
    def broken(service, **kwargs):
        raise RuntimeError("throttled")
    monkeypatch.setattr(handler.boto3, "client", broken)
    report = handler.build_report(result=load_fixture("normal.json"), today=TODAY, account_name="test-org", show_accounts=True)
    assert report["accounts"] is None


def test_accounts_merge_pages_and_give_up_past_the_cap(monkeypatch, load_fixture):
    pages = load_fixture("accounts.json")

    class TwoPages:
        def __init__(self):
            self.calls = 0

        def get_cost_and_usage(self, **query):
            self.calls += 1
            first = self.calls == 1
            return {"ResultsByTime": pages["ResultsByTime"][:4] if first else pages["ResultsByTime"][4:],
                    "DimensionValueAttributes": pages["DimensionValueAttributes"],
                    **({"NextPageToken": "next"} if first else {})}

    monkeypatch.setattr(handler.boto3, "client", lambda service, **kwargs: TwoPages())
    merged = handler.get_accounts(datetime.date(2026, 10, 15), datetime.date(2026, 10, 23), "UnblendedCost")
    assert len(merged["ResultsByTime"]) == 8

    class Endless:
        calls = 0

        def get_cost_and_usage(self, **query):
            Endless.calls += 1
            return {"ResultsByTime": [], "NextPageToken": "more"}

    monkeypatch.setattr(handler.boto3, "client", lambda service, **kwargs: Endless())
    assert handler.get_accounts(datetime.date(2026, 10, 15), datetime.date(2026, 10, 23), "UnblendedCost") is None
    assert Endless.calls == handler.breakdown_max_pages


def test_accounts_in_the_thread_reply(load_fixture):
    report = accounts_report(load_fixture)
    payload = handler.render_thread_blocks(report)
    assert [b["type"] for b in payload["blocks"]] == ["section", "table", "context"]
    assert texts(payload) == ["*By account*"]
    table = table_of(payload)["rows"]
    assert cell_text(table[0][0]) == "Account"
    assert [cell_text(r[0]) for r in table[1:]] == [r["name"] for r in report["accounts"]]


def test_no_thread_reply_without_anything_for_it():
    assert handler.render_thread_blocks(quiet_report()) is None


def test_thread_reply_text(load_fixture):
    text = handler.render_thread_text(accounts_report(load_fixture))
    assert text.startswith("Account")
    assert "example-shared" in text and handler.partial_note in text


# --- posting with the bot (E) -------------------------------------------------

def bot_env(monkeypatch, show_accounts="true"):
    monkeypatch.setenv("SLACK_BOT_TOKEN_SECRET_ID", "bot-secret")
    monkeypatch.setenv("SLACK_CHANNEL_ID", "C0TEST")
    monkeypatch.setenv("SLACK_WEBHOOK_URL", "https://hook")
    monkeypatch.setenv("SHOW_ACCOUNTS", show_accounts)
    monkeypatch.setattr(handler, "get_secret", lambda secret_id: "xoxb-test")


def fake_slack(responses=None):
    """chat.postMessage stand-in: answers from `responses` in order, else ok with ts '1.0', '2.0'..."""
    calls = []

    def call(token, method, payload):
        calls.append((method, payload))
        if responses:
            return responses.pop(0)
        return {"ok": True, "ts": f"{len(calls)}.0"}
    return calls, call


def test_bot_posts_the_report_and_the_accounts_in_its_thread(monkeypatch, load_fixture):
    report, seen = accounts_report(load_fixture), {}
    calls, call = fake_slack()
    webhook = []
    bot_env(monkeypatch)
    monkeypatch.setattr(handler, "build_report", lambda **kwargs: seen.update(kwargs) or report)
    monkeypatch.setattr(handler, "slack_api", call)
    monkeypatch.setattr(handler, "post_json", lambda url, payload: webhook.append(payload) or (200, "ok"))

    handler.lambda_handler({}, None)

    assert seen["show_accounts"] is True
    assert [(m, p["channel"], p.get("thread_ts")) for m, p in calls] == [
        ("chat.postMessage", "C0TEST", None), ("chat.postMessage", "C0TEST", "1.0")]
    assert calls[0][1]["blocks"] == handler.render_blocks(report, threaded=True)["blocks"]
    assert calls[1][1]["blocks"] == handler.render_thread_blocks(report)["blocks"]
    assert webhook == []


def test_accounts_can_be_turned_off(monkeypatch, load_fixture):
    report, seen = accounts_report(load_fixture), {}
    calls, call = fake_slack()
    bot_env(monkeypatch, show_accounts="false")
    monkeypatch.setattr(handler, "build_report", lambda **kwargs: seen.update(kwargs) or dict(report, accounts=None))
    monkeypatch.setattr(handler, "slack_api", call)

    handler.lambda_handler({}, None)

    assert seen["show_accounts"] is False
    assert len(calls) == 1


def test_accounts_need_the_bot(monkeypatch, load_fixture):
    seen, report = {}, quiet_report()
    monkeypatch.setenv("SHOW_ACCOUNTS", "true")
    monkeypatch.setattr(handler, "build_report", lambda **kwargs: seen.update(kwargs) or report)
    monkeypatch.setattr(handler, "post_json", lambda url, payload: (200, "ok"))
    monkeypatch.setenv("SLACK_WEBHOOK_URL", "https://hook")

    handler.lambda_handler({}, None)

    # not queried: there would be nowhere to post it
    assert seen["show_accounts"] is False


def test_bot_retries_rejected_blocks_as_text(monkeypatch):
    calls, call = fake_slack([{"ok": False, "error": "invalid_blocks"}, {"ok": True, "ts": "9.0"}])
    monkeypatch.setattr(handler, "slack_api", call)

    ts = handler.post_message("xoxb", "C0TEST", "summary", "table", {"text": "summary", "blocks": []}, thread_ts="1.0")

    assert ts == "9.0"
    assert calls[1][1] == {"channel": "C0TEST", "thread_ts": "1.0", "text": "summary\n\n```\ntable\n```"}


@pytest.mark.parametrize("token_fails", [False, True])
def test_webhook_posts_when_the_bot_cannot(monkeypatch, load_fixture, token_fails):
    report = accounts_report(load_fixture)
    calls, call = fake_slack([{"ok": False, "error": "not_in_channel"}] * 2)
    webhook = []
    bot_env(monkeypatch)
    if token_fails:
        def no_token(secret_id):
            raise RuntimeError("AccessDenied")
        monkeypatch.setattr(handler, "get_secret", no_token)
    monkeypatch.setattr(handler, "build_report", lambda **kwargs: report)
    monkeypatch.setattr(handler, "slack_api", call)
    monkeypatch.setattr(handler, "post_json", lambda url, payload: webhook.append(payload) or (200, "ok"))

    handler.lambda_handler({}, None)

    assert len(calls) == (0 if token_fails else 2)
    # the report goes out through the webhook; the accounts reply, with no thread, does not
    assert webhook == [handler.render_blocks(report)]


def test_slack_api_turns_network_errors_into_a_result(monkeypatch):
    def down(*args, **kwargs):
        raise OSError("timed out")
    monkeypatch.setattr(handler.urllib.request, "urlopen", down)
    assert handler.slack_api("xoxb", "chat.postMessage", {}) == {"ok": False, "error": "timed out"}


# --- titled layout ------------------------------------------------------------

def budget_of(actual, limit, forecast=None):
    spend = {"ActualSpend": {"Amount": str(actual)}}
    if forecast is not None:
        spend["ForecastedSpend"] = {"Amount": str(forecast)}
    return {"BudgetLimit": {"Amount": str(limit)}, "CalculatedSpend": spend}


def test_budget_short_line_warns_only_over_the_limit():
    assert handler.budget_short_line(budget_of(885.32, 750, 953.44)) == (
        "Budget: $885.32 of $750.00 (118%) :warning: · forecast $953.44")
    assert handler.budget_short_line(budget_of(750, 750)) == "Budget: $750.00 of $750.00 (100%)"


def test_budget_without_month_summary_gets_a_generic_title(load_fixture):
    report = handler.build_report(result=load_fixture("normal.json"), budget=budget_of(40, 100),
                                  today=TODAY, account_name="test-org")
    assert texts(handler.render_blocks(report))[1] == "*This month*\nBudget: $40.00 of $100.00 (40%)"


def test_table_title_follows_the_grouping(load_fixture):
    report = handler.build_report(result=load_fixture("normal.json"), group_by="LINKED_ACCOUNT",
                                  today=TODAY, account_name="test-org")
    assert "*Top items*" in texts(handler.render_blocks(report))


def test_threaded_footer_says_more_only_when_there_is_a_thread(load_fixture):
    footer = handler.render_blocks(quiet_report(), threaded=True)["blocks"][-1]["elements"][0]["text"]
    assert "thread" not in footer


def test_bot_posts_no_reply_without_anything_for_the_thread(monkeypatch):
    calls, call = fake_slack()
    monkeypatch.setattr(handler, "slack_api", call)
    assert handler.post_with_bot("xoxb", "C0TEST", quiet_report(), "full") == "1.0"
    assert len(calls) == 1


def test_bot_posts_the_compact_line_and_still_the_thread(monkeypatch, load_fixture):
    report = accounts_report(load_fixture)
    calls, call = fake_slack()
    monkeypatch.setattr(handler, "slack_api", call)
    handler.post_with_bot("xoxb", "C0TEST", report, "compact")
    assert calls[0][1]["blocks"] == handler.render_compact_blocks(report)["blocks"]
    assert calls[1][1]["thread_ts"] == "1.0"


def test_lambda_links_the_help_url(monkeypatch, load_fixture):
    report = accounts_report(load_fixture)
    calls, call = fake_slack()
    bot_env(monkeypatch)
    monkeypatch.setenv("REPORT_HELP_URL", "https://example.com/readme#how")
    monkeypatch.setattr(handler, "build_report", lambda **kwargs: report)
    monkeypatch.setattr(handler, "slack_api", call)

    handler.lambda_handler({}, None)

    assert "<https://example.com/readme#how|How to read this report>" in calls[0][1]["blocks"][-1]["elements"][0]["text"]


def test_thread_summary_says_what_the_reply_holds(load_fixture):
    report = accounts_report(load_fixture, alert_min_usd=1.0, anomaly_days=14, anomalies_result=ANOMALIES[:1])
    assert handler.render_thread_blocks(report)["text"] == (
        "Details · 2026-10-22 (partial): 1 anomaly · cost by account")


def test_details_go_to_the_channel_when_the_reply_fails(monkeypatch, load_fixture):
    report = accounts_report(load_fixture)
    calls, call = fake_slack([{"ok": True, "ts": "1.0"}] + [{"ok": False, "error": "ratelimited"}] * 2)
    monkeypatch.setattr(handler, "slack_api", call)

    assert handler.post_with_bot("xoxb", "C0TEST", report, "full") == "1.0"

    # report, reply (blocks, then text), then the details unthreaded
    assert [p.get("thread_ts") for _, p in calls] == [None, "1.0", "1.0", None]
    assert calls[3][1]["blocks"] == handler.render_thread_blocks(report)["blocks"]
