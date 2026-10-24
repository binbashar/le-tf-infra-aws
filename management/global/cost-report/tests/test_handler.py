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
