"""
Monthly AWS cost report by email.

Runs in the management (payer) account, where Cost Explorer returns the whole
organization's bill, so one query covers every account: no per-account roles.
Sends one email per month through SES: the installation's recipients in To and,
until BINBASH_REPORTING_UNTIL, the binbash copy in Cc.

The module is split so it can be tested without AWS: fetch_* read AWS,
build_report turns the raw data into a report, render_html formats it, and
lambda_handler wires them together.
"""
import datetime
import html
import logging
import os
from decimal import Decimal
from email.utils import parseaddr

import boto3
from botocore.config import Config

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Credits and refunds are shown as their own invoice lines, never mixed into
# the account and service tables, so those show what was consumed.
CREDIT_TYPES = ["Credit", "Refund"]
EXCLUDE_CREDITS = {"Not": {"Dimensions": {"Key": "RECORD_TYPE", "Values": CREDIT_TYPES}}}

# Cost Explorer RECORD_TYPE values as invoice lines; unknown types keep their name
RECORD_TYPE_LABELS = {
    "Usage": "Usage",
    "DiscountedUsage": "Usage covered by Reserved Instances",
    "SavingsPlanCoveredUsage": "Usage covered by Savings Plans",
    "SavingsPlanNegation": "Savings Plans coverage",
    "SavingsPlanRecurringFee": "Savings Plans fees",
    "SavingsPlanUpfrontFee": "Savings Plans upfront fees",
    "RIFee": "Reserved Instance fees",
    "Fee": "Fees",
    "Support": "Support",
    "Tax": "Tax",
    "Other": "Marketplace and other",
    "FlatRateSubscription": "Subscriptions",
    "BundledDiscount": "Bundled discounts",
    "Credit": "Credits",
    "Refund": "Refunds",
}

CENT = Decimal("0.005")

# Optional signals must never cost the month's report: fail fast, no retries
optional_call_config = Config(connect_timeout=5, read_timeout=10, retries={"max_attempts": 1})


# --- dates --------------------------------------------------------------------

def add_months(day: datetime.date, months: int):
    """The first day of the month `months` away from day's month."""
    index = day.year * 12 + day.month - 1 + months
    return datetime.date(index // 12, index % 12 + 1, 1)


def report_months(today: datetime.date, month: str = None):
    """
    (previous month start, report month start, report month end) for the
    month before today's, or for `month` ("YYYY-MM"). The end is exclusive,
    as Cost Explorer expects.
    """
    start = datetime.date.fromisoformat(f"{month}-01") if month else add_months(today, -1)
    return add_months(start, -1), start, add_months(start, 1)


# --- configuration ------------------------------------------------------------

def split_addresses(value: str):
    return [address.strip() for address in (value or "").split(",") if address.strip()]


def config_from_env(env=os.environ):
    """The report's settings, from the Lambda environment."""
    return {
        "organization": env.get("ORGANIZATION_NAME", "AWS"),
        "sender": env["SENDER"],
        "recipients": split_addresses(env.get("RECIPIENTS")),
        "binbash_recipients": split_addresses(env.get("BINBASH_RECIPIENTS")),
        "binbash_until": env.get("BINBASH_REPORTING_UNTIL", ""),
        "account_id": env.get("ACCOUNT_ID", ""),
        "budget_name": env.get("BUDGET_NAME", ""),
        "change_min_usd": Decimal(env.get("CHANGE_MIN_USD", "1")),
        "top_n": int(env.get("TOP_N", "3")),
        "anomaly_min_usd": Decimal(env.get("ANOMALY_MIN_USD", "10")),
        "untagged_tag_key": env.get("UNTAGGED_TAG_KEY", ""),
    }


def destinations(config: dict, today: datetime.date):
    """
    (To, Cc). binbash is copied until BINBASH_REPORTING_UNTIL, inclusive, and
    never without a date: the copy is tied to a contract, and the date is
    what ends it without anyone having to remember.
    """
    to = config["recipients"]
    if not to:
        raise ValueError("RECIPIENTS is empty")
    cc = []
    if config["binbash_recipients"]:
        if not config["binbash_until"]:
            raise ValueError("BINBASH_RECIPIENTS is set without BINBASH_REPORTING_UNTIL")
        if today <= datetime.date.fromisoformat(config["binbash_until"]):
            cc = [address for address in config["binbash_recipients"] if address not in to]
    return to, cc


# --- AWS reads ----------------------------------------------------------------

def get_all(call, **request):
    """Every page of a Cost Explorer *ResultsByTime response, merged by period."""
    results = []
    while True:
        page = call(**request)
        results += page["ResultsByTime"]
        if not page.get("NextPageToken"):
            return results
        request["NextPageToken"] = page["NextPageToken"]


def fetch_costs(ce, start: datetime.date, end: datetime.date):
    """{month start: {(account id, service): cost}}, credits and refunds excluded."""
    costs = {}
    for period in get_all(
        ce.get_cost_and_usage,
        TimePeriod={"Start": start.isoformat(), "End": end.isoformat()},
        Granularity="MONTHLY",
        Metrics=["UnblendedCost"],
        Filter=EXCLUDE_CREDITS,
        GroupBy=[{"Type": "DIMENSION", "Key": "LINKED_ACCOUNT"}, {"Type": "DIMENSION", "Key": "SERVICE"}],
    ):
        month = costs.setdefault(period["TimePeriod"]["Start"], {})
        for group in period.get("Groups", []):
            key = tuple(group["Keys"])
            month[key] = month.get(key, Decimal(0)) + Decimal(group["Metrics"]["UnblendedCost"]["Amount"])
    return costs


def fetch_record_types(ce, start: datetime.date, end: datetime.date):
    """{month start: {record type: cost}}: the invoice lines, credits included."""
    lines = {}
    for period in get_all(
        ce.get_cost_and_usage,
        TimePeriod={"Start": start.isoformat(), "End": end.isoformat()},
        Granularity="MONTHLY",
        Metrics=["UnblendedCost"],
        GroupBy=[{"Type": "DIMENSION", "Key": "RECORD_TYPE"}],
    ):
        lines[period["TimePeriod"]["Start"]] = {
            group["Keys"][0]: Decimal(group["Metrics"]["UnblendedCost"]["Amount"]) for group in period.get("Groups", [])
        }
    return lines


def fetch_account_names(organizations):
    """{account id: name}; empty when Organizations cannot be read (ids are shown instead)."""
    try:
        names = {}
        for page in organizations.get_paginator("list_accounts").paginate():
            names.update({account["Id"]: account["Name"] for account in page["Accounts"]})
        return names
    except Exception as e:
        logger.warning(f"Could not list accounts: {e}")
        return {}


def optional(name):
    """Run an optional read: log and return None on any error."""
    def wrap(fetch):
        def run(*args, **kwargs):
            try:
                return fetch(*args, **kwargs)
            except Exception as e:
                logger.warning(f"Could not read {name}: {e}")
                return None
        return run
    return wrap


@optional("the forecast")
def fetch_forecast(ce, today: datetime.date):
    """
    The current month's month-to-date cost and its forecast total, credits
    and refunds excluded, or None on the 1st (no month-to-date yet).
    """
    month_start, next_month = today.replace(day=1), add_months(today, 1)
    if today == month_start:
        return None
    mtd = get_all(
        ce.get_cost_and_usage,
        TimePeriod={"Start": month_start.isoformat(), "End": today.isoformat()},
        Granularity="MONTHLY",
        Metrics=["UnblendedCost"],
        Filter=EXCLUDE_CREDITS,
    )
    month_to_date = sum(Decimal(p["Total"]["UnblendedCost"]["Amount"]) for p in mtd)
    rest = ce.get_cost_forecast(
        TimePeriod={"Start": today.isoformat(), "End": next_month.isoformat()},
        Metric="UNBLENDED_COST",
        Granularity="MONTHLY",
        Filter=EXCLUDE_CREDITS,
    )
    return {
        "month": month_start,
        "month_to_date": month_to_date,
        "forecast": month_to_date + Decimal(rest["Total"]["Amount"]),
    }


@optional("the budget")
def fetch_budget(budgets, account_id: str, name: str):
    if not name:
        return None
    budget = budgets.describe_budget(AccountId=account_id, BudgetName=name)["Budget"]
    spend = budget.get("CalculatedSpend", {})
    return {
        "name": name,
        "limit": Decimal(budget["BudgetLimit"]["Amount"]),
        "actual": Decimal(spend.get("ActualSpend", {}).get("Amount", "0")),
        "forecast": Decimal(spend["ForecastedSpend"]["Amount"]) if "ForecastedSpend" in spend else None,
    }


@optional("the anomalies")
def fetch_anomalies(ce, start: datetime.date, end: datetime.date, min_usd: Decimal):
    """Cost Anomaly Detection anomalies in [start, end) with at least min_usd of impact."""
    request = {
        "DateInterval": {"StartDate": start.isoformat(), "EndDate": (end - datetime.timedelta(days=1)).isoformat()},
        "TotalImpact": {"NumericOperator": "GREATER_THAN_OR_EQUAL", "StartValue": float(min_usd)},
    }
    anomalies = []
    while True:
        page = ce.get_anomalies(**request)
        for anomaly in page.get("Anomalies", []):
            cause = (anomaly.get("RootCauses") or [{}])[0]
            anomalies.append({
                "start": anomaly.get("AnomalyStartDate", "")[:10],
                "impact": Decimal(str(anomaly["Impact"]["TotalImpact"])),
                "service": cause.get("Service", "Unknown service"),
                "account": cause.get("LinkedAccount", ""),
                "feedback": anomaly.get("Feedback", ""),
            })
        if not page.get("NextPageToken"):
            return sorted(anomalies, key=lambda a: a["impact"], reverse=True)
        request["NextPageToken"] = page["NextPageToken"]


@optional("the Savings Plans coverage")
def fetch_sp_coverage(ce, start: datetime.date, end: datetime.date):
    periods = ce.get_savings_plans_coverage(
        TimePeriod={"Start": start.isoformat(), "End": end.isoformat()}, Granularity="MONTHLY"
    ).get("SavingsPlansCoverages", [])
    if not periods:
        return None
    coverage = periods[0]["Coverage"]
    return {
        "percentage": Decimal(coverage.get("CoveragePercentage") or "0"),
        "on_demand": Decimal(coverage.get("OnDemandCost") or "0"),
    }


@optional("the untagged spend")
def fetch_untagged(ce, start: datetime.date, end: datetime.date, tag_key: str):
    """(untagged cost, total cost) for tag_key, credits and refunds excluded."""
    if not tag_key:
        return None
    untagged = total = Decimal(0)
    for period in get_all(
        ce.get_cost_and_usage,
        TimePeriod={"Start": start.isoformat(), "End": end.isoformat()},
        Granularity="MONTHLY",
        Metrics=["UnblendedCost"],
        Filter=EXCLUDE_CREDITS,
        GroupBy=[{"Type": "TAG", "Key": tag_key}],
    ):
        for group in period.get("Groups", []):
            amount = Decimal(group["Metrics"]["UnblendedCost"]["Amount"])
            total += amount
            if group["Keys"][0] == f"{tag_key}$":
                untagged += amount
    return {"tag_key": tag_key, "untagged": untagged, "total": total}


@optional("the credits")
def fetch_credits(billing, account_id: str, today: datetime.date):
    """
    Remaining balance of the organization's active credits, per currency, with
    the nearest expiration. remainingAmount is not zeroed when a credit
    expires, so only active, enabled credits count.
    """
    if not account_id:
        return None
    now = datetime.datetime.combine(today, datetime.time(), tzinfo=datetime.timezone.utc)
    credits = billing.get_credits(
        accountId=account_id, startDate=now - datetime.timedelta(days=364), payerAccountFlag=True)["credits"]
    balances, expires = {}, None
    for credit in credits:
        start, end = credit.get("startDate"), credit.get("endDate")
        if credit.get("creditStatus") == "DISABLED" or (start and start > now) or (end and end <= now):
            continue
        remaining = credit.get("remainingAmount") or {}
        amount = Decimal(remaining.get("currencyAmount") or "0")
        if amount <= 0:
            continue
        currency = remaining.get("currencyCode", "USD")
        balances[currency] = balances.get(currency, Decimal(0)) + amount
        if end and end.year < 2099 and (expires is None or end < expires):
            expires = end
    if not balances:
        return None
    return {"balances": balances, "expires": expires.date() if expires else None}


# --- report -------------------------------------------------------------------

def change(current: Decimal, previous: Decimal):
    return {"current": current, "previous": previous, "delta": current - previous}


def build_report(config: dict, today: datetime.date, months: tuple, costs: dict, record_types: dict,
                 names: dict, extras: dict = None):
    """The report as plain data, ready to render."""
    previous_start, start, end = months
    current = costs.get(start.isoformat(), {})
    previous = costs.get(previous_start.isoformat(), {})

    accounts, services = {}, {}
    for (account, service) in set(current) | set(previous):
        now, before = current.get((account, service), Decimal(0)), previous.get((account, service), Decimal(0))
        if abs(now) < CENT and abs(before) < CENT:
            continue
        rows = accounts.setdefault(account, {})
        rows[service] = change(now, before)
        total = services.setdefault(service, change(Decimal(0), Decimal(0)))
        services[service] = change(total["current"] + now, total["previous"] + before)

    def ordered(rows: dict):
        return sorted(rows.items(), key=lambda item: (item[1]["current"], item[1]["previous"], item[0]), reverse=True)

    account_rows = []
    for account, rows in accounts.items():
        totals = change(sum(r["current"] for r in rows.values()), sum(r["previous"] for r in rows.values()))
        account_rows.append({"id": account, "name": names.get(account, account), **totals, "services": ordered(rows)})
    account_rows.sort(key=lambda a: (a["current"], a["previous"], a["name"]), reverse=True)

    gross = change(sum(a["current"] for a in account_rows), sum(a["previous"] for a in account_rows))
    lines_now, lines_before = record_types.get(start.isoformat(), {}), record_types.get(previous_start.isoformat(), {})
    invoice = [
        {"type": record_type, "label": RECORD_TYPE_LABELS.get(record_type, record_type),
         **change(lines_now.get(record_type, Decimal(0)), lines_before.get(record_type, Decimal(0)))}
        for record_type in set(lines_now) | set(lines_before)
    ]
    invoice = [line for line in invoice if abs(line["current"]) >= CENT or abs(line["previous"]) >= CENT]
    # Charges first, largest first; credits and refunds last
    invoice.sort(key=lambda line: (line["type"] in CREDIT_TYPES, -abs(line["current"]), line["label"]))
    net = change(sum(line["current"] for line in invoice), sum(line["previous"] for line in invoice))

    top_n, min_usd = config["top_n"], config["change_min_usd"]
    increases = [(name, row) for name, row in services.items() if row["delta"] >= min_usd]
    increases.sort(key=lambda item: item[1]["delta"], reverse=True)

    return {
        "organization": config["organization"],
        "month": start,
        "previous_month": previous_start,
        # Month-end support, tax and Savings Plans charges post during the first days
        "preliminary": today < end.replace(day=5),
        "generated": today,
        "change_min_usd": min_usd,
        "gross": gross,
        "net": net,
        "invoice": invoice,
        "accounts": account_rows,
        "top_increases": increases[:top_n],
        "top_accounts": account_rows[:top_n],
        "names": names,
        **(extras or {}),
    }


# --- rendering ----------------------------------------------------------------

STYLE_TABLE = "border-collapse:collapse;width:100%;margin:8px 0 20px;font-size:13px"
STYLE_TH = "text-align:left;padding:6px 8px;border-bottom:2px solid #d0d7de;background:#f6f8fa"
STYLE_TD = "padding:5px 8px;border-bottom:1px solid #eaeef2"
UP, DOWN, MUTED = "#b42318", "#067647", "#667085"


def money(amount: Decimal, sign: bool = False):
    text = f"${abs(amount):,.2f}"
    if amount < 0 and abs(amount) >= CENT:
        return f"-{text}"
    return f"+{text}" if sign and amount >= CENT else text


def percent(current: Decimal, previous: Decimal):
    if abs(previous) < Decimal("0.01"):
        return "new" if abs(current) >= Decimal("0.01") else "—"
    return f"{(current - previous) / abs(previous):+.0%}"


def delta_cells(row: dict, min_usd: Decimal):
    """Δ$ and Δ% cells; colored only when the change is at least min_usd."""
    delta = row["delta"]
    color = MUTED if abs(delta) < min_usd else (UP if delta > 0 else DOWN)
    style = f"{STYLE_TD};text-align:right;color:{color};white-space:nowrap"
    return (f'<td style="{style}">{money(delta, sign=True)}</td>'
            f'<td style="{style}">{percent(row["current"], row["previous"])}</td>')


def table(headers: list, rows: list, report: dict, bold_last: bool = False):
    """A table of (label, change) rows with the two months, Δ$ and Δ%."""
    head = "".join(
        f'<th style="{STYLE_TH}{";text-align:right" if i else ""}">{html.escape(h)}</th>' for i, h in enumerate(headers)
    )
    body = []
    for i, (label, row) in enumerate(rows):
        weight = ";font-weight:600" if bold_last and i == len(rows) - 1 else ""
        body.append(
            f'<tr><td style="{STYLE_TD}{weight}">{html.escape(label)}</td>'
            f'<td style="{STYLE_TD};text-align:right{weight}">{money(row["current"])}</td>'
            f'<td style="{STYLE_TD};text-align:right;color:{MUTED}">{money(row["previous"])}</td>'
            f'{delta_cells(row, report["change_min_usd"])}</tr>'
        )
    return f'<table style="{STYLE_TABLE}"><tr>{head}</tr>{"".join(body)}</table>'


def month_headers(report: dict, first: str):
    return [first, f'{report["month"]:%b %Y}', f'{report["previous_month"]:%b %Y}', "Δ $", "Δ %"]


def summary_items(report: dict):
    """The 'At a glance' bullet points, skipping signals that were not read."""
    items = []
    if report["top_increases"]:
        items.append("Top increases: " + ", ".join(
            f"{html.escape(name)} {money(row['delta'], sign=True)}" for name, row in report["top_increases"]))
    if report["top_accounts"]:
        items.append("Top accounts: " + ", ".join(
            f"{html.escape(a['name'])} {money(a['current'])}" for a in report["top_accounts"]))
    forecast = report.get("forecast")
    if forecast:
        items.append(f"{forecast['month']:%B} forecast: {money(forecast['forecast'])} "
                     f"({money(forecast['month_to_date'])} so far, before credits)")
    budget = report.get("budget")
    if budget:
        line = f"Budget {html.escape(budget['name'])}: {money(budget['actual'])} of {money(budget['limit'])}"
        if budget["limit"]:
            used = budget["actual"] / budget["limit"]
            line += f" ({used:.0%})" + (f' <b style="color:{UP}">over budget</b>' if used > 1 else "")
        if budget["forecast"] is not None:
            line += f", forecast {money(budget['forecast'])}"
        items.append(line)
    credits = report.get("credits")
    if credits:
        balances = ", ".join(f"{amount:,.2f} {currency}" for currency, amount in sorted(credits["balances"].items()))
        expiry = f", next expiry {credits['expires']:%Y-%m-%d}" if credits["expires"] else ""
        items.append(f"Credits remaining: {balances}{expiry}")
    coverage = report.get("sp_coverage")
    if coverage:
        items.append(f"Savings Plans coverage: {coverage['percentage']:.0f}% "
                     f"({money(coverage['on_demand'])} on demand)")
    untagged = report.get("untagged")
    if untagged and untagged["total"]:
        share = untagged["untagged"] / untagged["total"]
        items.append(f"Untagged spend ({html.escape(untagged['tag_key'])}): {share:.0%} ({money(untagged['untagged'])})")
    anomalies = report.get("anomalies")
    if anomalies is not None:
        items.append(f"Cost anomalies: {len(anomalies)}" if anomalies else "Cost anomalies: none")
    return items


def subject(report: dict):
    return f"[{report['organization']}] AWS cost report — {report['month']:%B %Y}"


def render_html(report: dict):
    net, gross, min_usd = report["net"], report["gross"], report["change_min_usd"]
    color = MUTED if abs(net["delta"]) < min_usd else (UP if net["delta"] > 0 else DOWN)
    parts = [
        '<div style="font-family:-apple-system,Segoe UI,Helvetica,Arial,sans-serif;color:#101828;max-width:900px">',
        f'<h2 style="margin:0 0 4px">{html.escape(subject(report))}</h2>',
    ]
    if report["preliminary"]:
        parts.append(f'<p style="color:{UP};margin:4px 0">Preliminary: month-end charges may still be posting.</p>')
    parts.append(
        f'<p style="font-size:16px;margin:12px 0">Total {report["month"]:%B}: <b>{money(net["current"])}</b> '
        f'<span style="color:{color}">({money(net["delta"], sign=True)}, {percent(net["current"], net["previous"])} '
        f'vs {report["previous_month"]:%B})</span><br>'
        f'<span style="color:{MUTED};font-size:13px">{money(gross["current"])} before credits and refunds</span></p>'
    )
    items = summary_items(report)
    if items:
        parts.append('<h3 style="margin:16px 0 4px">At a glance</h3><ul style="margin:0;padding-left:20px">')
        parts += [f'<li style="margin:3px 0">{item}</li>' for item in items]
        parts.append("</ul>")

    parts.append('<h3 style="margin:20px 0 0">Invoice</h3>')
    invoice_rows = [(line["label"], line) for line in report["invoice"]] + [("Total", net)]
    parts.append(table(month_headers(report, "Line"), invoice_rows, report, bold_last=True))

    parts.append('<h3 style="margin:20px 0 0">By account</h3>')
    account_rows = [(f'{a["name"]} ({a["id"]})', a) for a in report["accounts"]] + [("Total", gross)]
    parts.append(table(month_headers(report, "Account"), account_rows, report, bold_last=True))

    anomalies = report.get("anomalies")
    if anomalies:
        parts.append('<h3 style="margin:20px 0 4px">Cost anomalies</h3><ul style="margin:0;padding-left:20px">')
        for anomaly in anomalies:
            account = report["names"].get(anomaly["account"], anomaly["account"])
            parts.append(
                f'<li style="margin:3px 0">{money(anomaly["impact"])} · {html.escape(anomaly["service"])}'
                f'{" · " + html.escape(account) if account else ""} · since {html.escape(anomaly["start"])}'
                f'{" · feedback: " + html.escape(anomaly["feedback"]) if anomaly["feedback"] else ""}</li>')
        parts.append("</ul>")

    parts.append('<h3 style="margin:20px 0 0">By service, per account</h3>')
    for account in report["accounts"]:
        parts.append(f'<h4 style="margin:14px 0 0">{html.escape(account["name"])} '
                     f'<span style="color:{MUTED};font-weight:400">{html.escape(account["id"])} · '
                     f'{money(account["current"])}</span></h4>')
        rows = list(account["services"]) + [("Total", account)]
        parts.append(table(month_headers(report, "Service"), rows, report, bold_last=True))

    parts.append(
        f'<p style="color:{MUTED};font-size:12px;margin-top:24px">Unblended cost from Cost Explorer in the payer '
        f'account. The account and service tables exclude credits and refunds; the invoice lines include them, '
        f'so their total is the bill. Changes under {money(min_usd)} are not colored. '
        f'Generated {report["generated"]:%Y-%m-%d}.</p></div>'
    )
    return "".join(parts)


# --- handler ------------------------------------------------------------------

def send(ses, config: dict, to: list, cc: list, report_subject: str, body: str):
    destination = {"ToAddresses": to}
    if cc:
        destination["CcAddresses"] = cc
    ses.send_email(
        Source=config["sender"],
        Destination=destination,
        Message={"Subject": {"Data": report_subject, "Charset": "UTF-8"},
                 "Body": {"Html": {"Data": body, "Charset": "UTF-8"}}},
    )


def lambda_handler(event, context, today: datetime.date = None):
    """
    Build and send last month's report. The event may name another month
    ({"month": "2026-09"}) to send it again. Any error raises, so the
    function's Errors alarm fires.
    """
    config = config_from_env()
    today = today or datetime.datetime.now(datetime.timezone.utc).date()
    to, cc = destinations(config, today)
    months = report_months(today, (event or {}).get("month"))
    previous_start, start, end = months

    ce = boto3.client("ce", region_name="us-east-1")
    ce_optional = boto3.client("ce", region_name="us-east-1", config=optional_call_config)
    costs = fetch_costs(ce, previous_start, end)
    record_types = fetch_record_types(ce, previous_start, end)
    names = fetch_account_names(boto3.client("organizations", region_name="us-east-1", config=optional_call_config))
    extras = {
        "forecast": fetch_forecast(ce_optional, today),
        "budget": fetch_budget(boto3.client("budgets", region_name="us-east-1", config=optional_call_config),
                               config["account_id"], config["budget_name"]),
        "anomalies": fetch_anomalies(ce_optional, start, end, config["anomaly_min_usd"]),
        "sp_coverage": fetch_sp_coverage(ce_optional, start, end),
        "untagged": fetch_untagged(ce_optional, start, end, config["untagged_tag_key"]),
        "credits": fetch_credits(boto3.client("billing", region_name="us-east-1", config=optional_call_config),
                                 config["account_id"], today),
    }
    report = build_report(config, today, months, costs, record_types, names, extras)
    if not report["accounts"]:
        raise RuntimeError(f"Cost Explorer returned no costs for {start:%B %Y}")

    send(boto3.client("ses"), config, to, cc, subject(report), render_html(report))
    sender = parseaddr(config["sender"])[1]
    logger.info(f"Sent the {start:%Y-%m} report from {sender} to {len(to)} recipient(s), {len(cc)} in Cc")
    return {"month": f"{start:%Y-%m}", "to": len(to), "cc": len(cc), "accounts": len(report["accounts"])}
