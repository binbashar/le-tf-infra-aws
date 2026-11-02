"""Tests for src/report.py. From the layer directory: python3 -m pytest tests/ -q"""
import datetime
import re
from decimal import Decimal

import pytest

import report
import sample


def build(**config):
    return report.build_report({**sample.CONFIG, **config}, sample.TODAY, report.report_months(sample.TODAY),
                               sample.costs(), sample.record_types(), sample.ACCOUNTS, sample.EXTRAS)


def cells(html, label):
    """The text cells of the first table row whose first cell starts with label."""
    for row in re.findall(r"<tr>(.*?)</tr>", html, re.S):
        texts = [re.sub(r"<.*?>", "", c).strip() for c in re.findall(r"<td[^>]*>(.*?)</td>", row, re.S)]
        if texts and texts[0].startswith(label):
            return texts
    raise AssertionError(f"no row {label!r}")


# --- dates --------------------------------------------------------------------

def test_reports_the_month_before_today():
    assert report.report_months(datetime.date(2026, 11, 5)) == (
        datetime.date(2026, 9, 1), datetime.date(2026, 10, 1), datetime.date(2026, 11, 1))


def test_january_reports_december_of_the_previous_year():
    assert report.report_months(datetime.date(2027, 1, 5)) == (
        datetime.date(2026, 11, 1), datetime.date(2026, 12, 1), datetime.date(2027, 1, 1))


def test_event_can_name_the_month():
    assert report.report_months(sample.TODAY, "2026-03")[1:] == (datetime.date(2026, 3, 1), datetime.date(2026, 4, 1))


# --- recipients ---------------------------------------------------------------

def config(**overrides):
    return {**sample.CONFIG, **overrides}


def test_no_binbash_copy_by_default():
    assert report.destinations(config(), sample.TODAY) == (sample.CONFIG["recipients"], [])


def test_binbash_copy_until_the_date_inclusive():
    cfg = config(binbash_recipients=["finops@binbash.example"], binbash_until="2026-11-05")
    assert report.destinations(cfg, sample.TODAY)[1] == ["finops@binbash.example"]
    assert report.destinations(cfg, sample.TODAY + datetime.timedelta(days=1))[1] == []


def test_binbash_copy_needs_an_end_date():
    with pytest.raises(ValueError):
        report.destinations(config(binbash_recipients=["finops@binbash.example"]), sample.TODAY)


def test_no_recipients_raises():
    with pytest.raises(ValueError):
        report.destinations(config(recipients=[]), sample.TODAY)


def test_a_recipient_already_in_to_is_not_copied():
    cfg = config(binbash_recipients=["cfo@example.com"], binbash_until="2030-01-01")
    assert report.destinations(cfg, sample.TODAY)[1] == []


def test_config_reads_comma_separated_addresses():
    cfg = report.config_from_env({"SENDER": "a@example.com", "RECIPIENTS": " x@example.com, ,y@example.com "})
    assert cfg["recipients"] == ["x@example.com", "y@example.com"]
    assert cfg["binbash_recipients"] == []


# --- report -------------------------------------------------------------------

def test_invoice_reconciles_with_credits():
    data = build()
    assert data["net"]["current"] == Decimal("719.60")  # 414.60 + 625 - 320
    assert data["gross"]["current"] == Decimal("1039.60")  # account tables: credits excluded
    assert [line["label"] for line in data["invoice"]] == ["Marketplace and other", "Usage", "Credits"]


def test_accounts_sum_to_the_gross_total():
    data = build()
    assert sum(a["current"] for a in data["accounts"]) == data["gross"]["current"]
    assert [a["name"] for a in data["accounts"]] == ["management", "apps-prd", "apps-devstg"]


def test_service_that_dropped_to_zero_is_listed():
    services = dict(next(a for a in build()["accounts"] if a["name"] == "apps-prd")["services"])
    assert services["Amazon Redshift"]["current"] == 0
    assert services["Amazon Redshift"]["previous"] == Decimal("45.00")


def test_top_increases_aggregate_across_accounts_and_skip_small_moves():
    names = [name for name, _ in build()["top_increases"]]
    # EC2: +70 in apps-prd, -5 in apps-devstg = +65; RDS moved $0.40, under the $1 threshold
    assert names == ["Amazon Elastic Compute Cloud - Compute", "Amazon Bedrock", "AWS Cost Explorer"]
    assert "Amazon Relational Database Service" not in [n for n, _ in build(top_n=10)["top_increases"]]


def test_preliminary_before_the_fifth():
    months = report.report_months(sample.TODAY)
    early = report.build_report(sample.CONFIG, datetime.date(2026, 11, 2), months, sample.costs(),
                                sample.record_types(), sample.ACCOUNTS)
    assert early["preliminary"] and not build()["preliminary"]


# --- rendering ----------------------------------------------------------------

def test_subject_names_the_organization_and_month():
    assert report.subject(build()) == "[Example Org] AWS cost report — October 2026"


def test_new_service_shows_new_instead_of_a_percentage():
    assert cells(report.render_html(build()), "Amazon Bedrock")[1:] == ["$25.00", "$0.00", "+$25.00", "new"]


def test_small_changes_are_not_colored():
    html = report.render_html(build())
    rds = re.search(r"Amazon Relational Database Service</td>.*?</tr>", html, re.S).group(0)
    assert report.MUTED in rds and report.UP not in rds


def test_invoice_total_is_the_net_bill():
    assert cells(report.render_html(build()), "Total")[1:3] == ["$719.60", "$680.00"]


def test_names_are_escaped():
    data = report.build_report(sample.CONFIG, sample.TODAY, report.report_months(sample.TODAY), sample.costs(),
                               sample.record_types(), {"222222222222": "<b>prd</b>"})
    html = report.render_html(data)
    assert "<b>prd</b>" not in html and "&lt;b&gt;prd&lt;/b&gt;" in html


def test_summary_lists_every_signal_that_was_read():
    text = " | ".join(report.summary_items(build()))
    for expected in ("Top increases", "Top accounts", "November forecast: $1,080.00", "over budget",
                     "Credits remaining: 2,450.00 USD, next expiry 2027-03-31", "Savings Plans coverage: 0%",
                     "Untagged spend (Project): 12%", "Cost anomalies: 1"):
        assert expected in text, expected


def test_summary_skips_signals_that_could_not_be_read():
    data = report.build_report(sample.CONFIG, sample.TODAY, report.report_months(sample.TODAY), sample.costs(),
                               sample.record_types(), sample.ACCOUNTS,
                               {k: None for k in sample.EXTRAS})
    text = " | ".join(report.summary_items(data))
    assert "forecast" not in text and "Budget" not in text and "anomalies" not in text


# --- AWS reads ----------------------------------------------------------------

class FakeCE:
    """Cost Explorer stand-in answering from the sample data."""

    def __init__(self, fail=()):
        self.fail = fail
        self.calls = []

    def get_cost_and_usage(self, **query):
        self.calls.append(query)
        keys = [g["Key"] for g in query.get("GroupBy", [])]
        if keys == ["LINKED_ACCOUNT", "SERVICE"]:
            data, keys_of = sample.COSTS, list
        elif keys == ["RECORD_TYPE"]:
            data, keys_of = sample.RECORD_TYPES, lambda key: [key]
        else:
            return {"ResultsByTime": [{"TimePeriod": query["TimePeriod"], "Total": {"UnblendedCost": {"Amount": "150"}},
                                       "Groups": []}]}
        return {"ResultsByTime": [{"TimePeriod": {"Start": month}, "Groups": sample.ce_groups(rows, keys_of)}
                                  for month, rows in data.items()]}

    def __getattr__(self, name):
        def optional_call(**kwargs):
            raise RuntimeError(f"{name} unavailable")
        return optional_call


def test_fetch_costs_groups_by_account_and_service_without_credits():
    ce = FakeCE()
    costs = report.fetch_costs(ce, datetime.date(2026, 9, 1), datetime.date(2026, 11, 1))
    assert costs[sample.OCTOBER][("333333333333", "Amazon Bedrock")] == Decimal("25.00")
    assert ce.calls[0]["Filter"] == report.EXCLUDE_CREDITS


def test_fetch_costs_follows_pagination():
    pages = [
        {"ResultsByTime": [{"TimePeriod": {"Start": sample.OCTOBER}, "Groups": sample.ce_groups({("1", "A"): "1"})}],
         "NextPageToken": "next"},
        {"ResultsByTime": [{"TimePeriod": {"Start": sample.OCTOBER}, "Groups": sample.ce_groups({("1", "B"): "2"})}]},
    ]

    class Paged:
        def get_cost_and_usage(self, **query):
            return pages[1] if query.get("NextPageToken") else pages[0]

    costs = report.fetch_costs(Paged(), datetime.date(2026, 10, 1), datetime.date(2026, 11, 1))
    assert costs[sample.OCTOBER] == {("1", "A"): Decimal("1"), ("1", "B"): Decimal("2")}


def test_untagged_is_the_empty_tag_value():
    class Tagged:
        def get_cost_and_usage(self, **query):
            groups = sample.ce_groups({"Project$": "30", "Project$web": "70"}, lambda key: [key])
            return {"ResultsByTime": [{"TimePeriod": query["TimePeriod"], "Groups": groups}]}

    result = report.fetch_untagged(Tagged(), datetime.date(2026, 10, 1), datetime.date(2026, 11, 1), "Project")
    assert (result["untagged"], result["total"]) == (Decimal("30"), Decimal("100"))


def test_credits_count_only_active_enabled_balances():
    utc = datetime.timezone.utc
    day = lambda *d: datetime.datetime(*d, tzinfo=utc)  # noqa: E731

    class Billing:
        def get_credits(self, **kwargs):
            assert kwargs["payerAccountFlag"] is True and kwargs["accountId"] == "111111111111"
            return {"credits": [
                {"remainingAmount": {"currencyAmount": "1000", "currencyCode": "USD"},
                 "startDate": day(2026, 1, 1), "endDate": day(2027, 3, 31), "creditStatus": "ENABLED"},
                {"remainingAmount": {"currencyAmount": "500", "currencyCode": "USD"},
                 "startDate": day(2025, 1, 1), "endDate": day(2026, 6, 30), "creditStatus": "ENABLED"},  # expired
                {"remainingAmount": {"currencyAmount": "300", "currencyCode": "USD"},
                 "startDate": day(2026, 1, 1), "endDate": day(2099, 12, 31), "creditStatus": "DISABLED"},
                {"remainingAmount": {"currencyAmount": "200", "currencyCode": "USD"},
                 "startDate": day(2026, 1, 1), "endDate": day(2099, 12, 31), "creditStatus": "ENABLED"},
            ]}

    assert report.fetch_credits(Billing(), "111111111111", sample.TODAY) == {
        "balances": {"USD": Decimal("1200")}, "expires": datetime.date(2027, 3, 31)}


def test_optional_reads_return_none_on_errors():
    ce = FakeCE()
    assert report.fetch_anomalies(ce, datetime.date(2026, 10, 1), datetime.date(2026, 11, 1), Decimal(10)) is None
    assert report.fetch_sp_coverage(ce, datetime.date(2026, 10, 1), datetime.date(2026, 11, 1)) is None


# --- handler ------------------------------------------------------------------

@pytest.fixture
def aws(monkeypatch):
    """Fake boto3 clients; returns the list of sent emails."""
    sent = []

    class SES:
        def send_email(self, **kwargs):
            sent.append(kwargs)

    class Organizations:
        def get_paginator(self, name):
            class Paginator:
                def paginate(self):
                    return [{"Accounts": [{"Id": i, "Name": n} for i, n in sample.ACCOUNTS.items()]}]
            return Paginator()

    clients = {"ce": FakeCE(), "ses": SES(), "organizations": Organizations()}
    monkeypatch.setattr(report.boto3, "client", lambda name, **kwargs: clients.get(name, FakeCE()))
    for key, value in {"SENDER": "FinOps <finops@example.com>", "RECIPIENTS": "cfo@example.com",
                       "ORGANIZATION_NAME": "Example Org", "BINBASH_RECIPIENTS": "finops@binbash.example",
                       "BINBASH_REPORTING_UNTIL": "2027-12-31"}.items():
        monkeypatch.setenv(key, value)
    return sent


def test_handler_sends_one_email_with_the_binbash_copy(aws):
    result = report.lambda_handler({}, None, today=sample.TODAY)
    assert len(aws) == 1
    assert aws[0]["Destination"] == {"ToAddresses": ["cfo@example.com"], "CcAddresses": ["finops@binbash.example"]}
    assert aws[0]["Message"]["Subject"]["Data"] == "[Example Org] AWS cost report — October 2026"
    assert result == {"month": "2026-10", "to": 1, "cc": 1, "accounts": 3}


def test_handler_survives_every_optional_read_failing(aws):
    # FakeCE raises on forecast, anomalies and coverage; budgets and billing are FakeCE too
    report.lambda_handler({}, None, today=sample.TODAY)
    assert "At a glance" in aws[0]["Message"]["Body"]["Html"]["Data"]


def test_handler_raises_when_there_is_no_cost_data(aws, monkeypatch):
    monkeypatch.setattr(sample, "COSTS", {})
    with pytest.raises(RuntimeError):
        report.lambda_handler({}, None, today=sample.TODAY)
    assert aws == []
