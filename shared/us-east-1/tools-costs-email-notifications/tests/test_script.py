"""Tests for src/script.py. Run from the layer directory: python3 -m pytest tests/ -q"""
import json
import re

import pytest

# FORCE_DATE=2026-11-01 reports on October, compared with September
OCTOBER = "2026-10-01"
SEPTEMBER = "2026-09-01"


def groups(costs):
    return [{"Keys": [k], "Metrics": {"UnblendedCost": {"Amount": str(v), "Unit": "USD"}}} for k, v in costs.items()]


class FakeCE:
    """Cost Explorer stand-in: answers by month, and by tag when the query filters on one."""

    def __init__(self, months, tagged=None):
        self.months = months
        self.tagged = tagged or {}
        self.queries = []

    def get_cost_and_usage(self, **query):
        self.queries.append(query)
        start = query["TimePeriod"]["Start"]
        tag = find_tag(query["Filter"])
        costs = self.tagged.get(tag, {}) if tag else self.months.get(start, {})
        return {"ResultsByTime": [{"Groups": groups(costs)}]}


def find_tag(node):
    if "Tags" in node:
        return (node["Tags"]["Key"], node["Tags"]["Values"][0])
    for child in node.get("And", []):
        if found := find_tag(child):
            return found
    return None


def has_credit_filter(node):
    if "Not" in node:
        return node["Not"]["Dimensions"]["Key"] == "RECORD_TYPE"
    return any(has_credit_filter(child) for child in node.get("And", []))


@pytest.fixture
def run(load_script, monkeypatch):
    """Run the handler against a FakeCE; returns (script, ce, sent emails)."""
    def _run(months, tagged=None, **env):
        script = load_script(**env)
        ce = FakeCE(months, tagged)
        sent = []
        monkeypatch.setattr(script, "create_ce_client", lambda account_id: ce)

        class FakeSES:
            def send_email(self, **kwargs):
                sent.append(kwargs)

        monkeypatch.setattr(script.boto3, "client", lambda *a, **k: FakeSES())
        script.lambda_handler({}, None)
        return script, ce, sent
    return _run


def rows(html):
    """{service: [cell texts]} for every table row except the header."""
    out = {}
    for row in re.findall(r"<tr>(.*?)</tr>", html, re.S):
        cells = [re.sub(r"<.*?>", "", c).strip() for c in re.findall(r"<td[^>]*>(.*?)</td>", row, re.S)]
        out[cells[0]] = cells[1:]
    return out


# --- credits ------------------------------------------------------------------

@pytest.mark.parametrize("value, excluded", [("true", True), ("false", False), ("False", False), ("TRUE", True)])
def test_exclude_credits_reads_the_string_value(load_script, value, excluded):
    assert load_script(EXCLUDE_CREDITS=value).EXCLUDE_CREDITS is excluded


def test_credits_are_included_when_not_excluded(run):
    _, ce, _ = run({OCTOBER: {"EC2": 10}}, EXCLUDE_CREDITS="false")
    assert not any(has_credit_filter(q["Filter"]) for q in ce.queries)


def test_credits_are_excluded_by_default(run):
    _, ce, _ = run({OCTOBER: {"EC2": 10}}, EXCLUDE_CREDITS=None)
    assert all(has_credit_filter(q["Filter"]) for q in ce.queries)


# --- rows ---------------------------------------------------------------------

def test_service_that_dropped_to_zero_is_listed(run):
    _, _, sent = run({OCTOBER: {"EC2": 10}, SEPTEMBER: {"EC2": 8, "Redshift": 50}})
    table = rows(sent[0]["Message"]["Body"]["Html"]["Data"])
    assert table["Redshift"][:2] == ["$0.00", "$50.00"]
    assert table["Total"][:2] == ["$10.00", "$58.00"]


def test_rows_are_sorted_by_current_cost(run):
    _, _, sent = run({OCTOBER: {"S3": 1, "EC2": 10}, SEPTEMBER: {"Redshift": 50}})
    assert list(rows(sent[0]["Message"]["Body"]["Html"]["Data"])) == ["EC2", "S3", "Redshift", "Total"]


# --- tags ---------------------------------------------------------------------

def test_tag_columns_are_per_service(run):
    _, ce, sent = run(
        {OCTOBER: {"EC2": 10, "S3": 4}, SEPTEMBER: {"EC2": 10, "S3": 4}},
        tagged={("team", "data"): {"EC2": 3}},
        TAGS_JSON=json.dumps({"team": "data"}),
    )
    table = rows(sent[0]["Message"]["Body"]["Html"]["Data"])
    assert table["EC2"][3] == "$3.00"
    assert table["S3"][3] == "$0.00"
    assert table["Total"][3] == "$3.00"
    # current month + previous month + one per tag, for the single account
    assert len(ce.queries) == 3


@pytest.mark.parametrize("tags_json", ["not json", "[1, 2]", json.dumps({"a": "1", "b": "2", "c": "3", "d": "4"})])
def test_invalid_tags_raise_before_querying(run, tags_json):
    with pytest.raises(ValueError):
        run({OCTOBER: {"EC2": 10}}, TAGS_JSON=tags_json)


# --- failures -----------------------------------------------------------------

def test_no_configured_accounts_raises(run):
    with pytest.raises(RuntimeError):
        run({}, ACCOUNTS="{}", AUTO_DISCOVER_ACCOUNTS="false")


def test_auto_discovery_with_no_accounts_raises(load_script, monkeypatch):
    script = load_script(ACCOUNTS="{}", AUTO_DISCOVER_ACCOUNTS="true")
    monkeypatch.setattr(script, "discover_accounts", lambda: {})
    with pytest.raises(RuntimeError, match="No accounts"):
        script.lambda_handler({}, None)


def test_all_accounts_failing_raises_and_sends_nothing(load_script, monkeypatch):
    script = load_script()
    monkeypatch.setattr(script, "create_ce_client", lambda account_id: None)
    monkeypatch.setattr(script.boto3, "client", lambda *a, **k: pytest.fail("no email expected"))
    with pytest.raises(RuntimeError):
        script.lambda_handler({}, None)


# --- email --------------------------------------------------------------------

def test_one_email_to_every_recipient(run):
    _, _, sent = run({OCTOBER: {"EC2": 10}})
    assert len(sent) == 1
    assert sent[0]["Destination"] == {"ToAddresses": ["a@example.com", "b@example.com"]}


def test_query_dates_cover_last_month_and_the_one_before(run):
    _, ce, _ = run({OCTOBER: {"EC2": 10}})
    periods = {(q["TimePeriod"]["Start"], q["TimePeriod"]["End"]) for q in ce.queries}
    assert periods == {("2026-10-01", "2026-11-01"), ("2026-09-01", "2026-10-01")}
