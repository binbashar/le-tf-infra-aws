#
# Source: https://github.com/iandees/aws-billing-to-slack/tree/master
#
from collections import defaultdict
import boto3
import calendar
import datetime
import json
import os
import statistics
import urllib.error
import urllib.request

# Yesterday is compared against the average of the baseline_days days before
# it, so the query covers baseline_days + 1 days; the sparkline shows the last
# spark_days of them.
baseline_days = 7
n_days = baseline_days + 1
spark_days = 7

# A service whose every day stays under half a cent prints as $0.00 all week:
# it is folded into the "Other" row instead of taking a line of its own.
negligible_usd = 0.005

excluded_record_types = ["Credit", "Refund", "Upfront", "Support"]

metric_labels = {
    "UnblendedCost": "Unblended cost",
    "BlendedCost": "Blended cost",
    "AmortizedCost": "Amortized cost",
    "NetUnblendedCost": "Net unblended cost",
    "NetAmortizedCost": "Net amortized cost",
}

# Cost Explorer has usually not finished billing yesterday when the report
# runs, so yesterday's figure is always flagged as partial.
partial_note = "* partial: Cost Explorer may still add charges for this day"

# It seems that the sparkline symbols don't line up (probably based on font?) so put them last
# Also, leaving out the full block because Slack doesn't like it: '█'
sparks = ['▁', '▂', '▃', '▄', '▅', '▆', '▇']

def sparkline(datapoints):
    upper = max(datapoints)
    n_sparks = len(sparks) - 1

    line = ""
    for dp in datapoints:
        # An all-zero series is a flat floor, not a full bar
        scaled = 0 if upper == 0 else dp/upper
        which_spark = round(scaled * n_sparks)
        line += (sparks[which_spark])

    return line


def baseline(costs):
    """Average daily cost of the days before yesterday (costs[-1])."""
    return sum(costs[:-1]) / len(costs[:-1])


def pct_change(new: float, old: float):
    """'+12%', '-100%', 'new' when there is nothing to compare with, '-' when both are nil."""
    if old < negligible_usd:
        return "new" if new >= negligible_usd else "-"
    return f"{round((new / old - 1) * 100) + 0:+d}%"


def delta(costs):
    """
    Yesterday (costs[-1]) against the average of the days before it, for display.

    Returns:
        tuple: (change in USD rounded to cents, change as a string: '+12%',
                '-100%', 'new' when there was no baseline to compare with, or
                '-' when both are nil)
    """
    base = baseline(costs)
    # round() then + 0.0 turns -0.0 into 0.0, so a flat cost never prints "-0.00"
    usd = round(costs[-1] - base, 2) + 0.0
    return usd, pct_change(costs[-1], base)


def is_negligible(costs):
    return all(cost < negligible_usd for cost in costs)


def footer(cost_aggregation: str):
    metric = metric_labels.get(cost_aggregation, cost_aggregation)
    excluded = ", ".join(excluded_record_types[:-1]) + " and " + excluded_record_types[-1]
    return (
        f"∆: yesterday vs. the average of the previous {baseline_days} days\n"
        f"{metric}, excluding {excluded} records\n"
        f"{partial_note}\n"
    )


# Cost Explorer's service names, shortened so the table fits a phone screen
short_names = {
    "Amazon Elastic Compute Cloud - Compute": "EC2 - Compute",
    "Amazon EC2 Container Registry (ECR)": "ECR",
    "Amazon Elastic Container Service": "ECS",
    "Amazon Elastic Container Service for Kubernetes": "EKS",
    "Amazon Elastic File System": "EFS",
    "Amazon Elastic Load Balancing": "ELB",
    "Amazon Relational Database Service": "RDS",
    "Amazon Simple Email Service": "SES",
    "Amazon Simple Notification Service": "SNS",
    "Amazon Simple Queue Service": "SQS",
    "Amazon Simple Storage Service": "S3",
    "Amazon Virtual Private Cloud": "VPC",
    "AWS Key Management Service": "KMS",
    "AmazonCloudWatch": "CloudWatch",
}


def short_name(name: str):
    """'Amazon Simple Storage Service' -> 'S3', 'AWS Config' -> 'Config'."""
    if name in short_names:
        return short_names[name]
    name = name.replace("(Amazon Bedrock Edition)", "(Bedrock)")
    for prefix in ("Amazon ", "AWS "):
        if name.startswith(prefix):
            return name[len(prefix):]
    return name


def date_window(today: datetime.date):
    """
    The report covers the n_days days before `today` (UTC), `today` excluded.

    Returns:
        tuple: (week_ago, yesterday, list of the n_days dates as 'YYYY-MM-DD')
    """
    yesterday = today - datetime.timedelta(days=1)
    week_ago = today - datetime.timedelta(days=n_days)
    list_of_dates = [
        (week_ago + datetime.timedelta(days=x)).strftime('%Y-%m-%d')
        for x in range(n_days)
    ]
    return week_ago, yesterday, list_of_dates


def month_window(yesterday: datetime.date):
    """
    The month yesterday falls in, and the same stretch of the month before.
    On the 1st, yesterday is the last day of the previous month, so that
    month is reported whole.

    Returns:
        tuple: (start of last month, same day last month -- capped at that
                month's length --, start of this month)
    """
    month_start = yesterday.replace(day=1)
    last_month_end = month_start - datetime.timedelta(days=1)
    last_month_start = last_month_end.replace(day=1)
    same_point = last_month_start.replace(day=min(yesterday.day, last_month_end.day))
    return last_month_start, same_point, month_start


def month_summary(daily_totals: dict, yesterday: datetime.date):
    """
    Month to date against the same point last month, and the month-end pace:
    month to date plus, for each day left, the median of the baseline_days
    days before yesterday. The median, not the mean: a once-a-month charge
    (a Marketplace subscription, say) inside those days would otherwise be
    projected onto every remaining day. Every figure uses the report's own
    metric.

    Args:
        daily_totals: {'YYYY-MM-DD': total cost} from the start of last month
    """
    last_month_start, same_point, month_start = month_window(yesterday)

    def total(start, end):
        return sum(cost for day, cost in daily_totals.items()
                   if start.isoformat() <= day <= end.isoformat())

    month_to_date = total(month_start, yesterday)
    last_month_to_date = total(last_month_start, same_point)
    recent = [daily_totals.get((yesterday - datetime.timedelta(days=d)).isoformat(), 0.0)
              for d in range(1, baseline_days + 1)]
    days_left = calendar.monthrange(yesterday.year, yesterday.month)[1] - yesterday.day
    return {
        "month": month_start,
        "last_month": last_month_start,
        "month_to_date": month_to_date,
        "last_month_to_date": last_month_to_date,
        "pct": pct_change(month_to_date, last_month_to_date),
        "pace": month_to_date + statistics.median(recent) * days_left,
    }


def get_budget(budget_name: str):
    """
    The AWS Budget as reported by AWS Budgets, or None when it cannot be read:
    a budget problem must never stop the day's report.
    """
    try:
        account_id = boto3.client("sts").get_caller_identity()["Account"]
        return boto3.client("budgets").describe_budget(AccountId=account_id, BudgetName=budget_name)["Budget"]
    except Exception as e:
        print(f"Could not read budget {budget_name}: {e}")
        return None


def budget_line(budget: dict):
    """
    'AWS Budget (incl. tax, support; excl. credits): $874.64 of $750.00 (117%) · forecast $952.91'

    The figures are AWS Budgets' own, which counts charges this report
    excludes; the label is built from the budget's CostTypes so it says which.
    """
    types = budget.get("CostTypes", {})
    included = [label for flag, label in (
        ("IncludeTax", "tax"), ("IncludeSupport", "support"),
        ("IncludeUpfront", "upfront"), ("IncludeOtherSubscription", "Marketplace"),
    ) if types.get(flag)]
    label = "incl. " + ", ".join(included) if included else "usage only"
    label += "; " + ("incl." if types.get("IncludeCredit") else "excl.") + " credits"

    limit = float(budget["BudgetLimit"]["Amount"])
    spend = budget.get("CalculatedSpend", {})
    actual = float(spend.get("ActualSpend", {}).get("Amount", 0))
    line = f"AWS Budget ({label}): {money(actual)} of {money(limit)}"
    if limit:
        line += f" ({actual / limit:.0%})"
    if "ForecastedSpend" in spend:
        line += f" · forecast {money(float(spend['ForecastedSpend']['Amount']))}"
    return line


def get_account_name():
    # Get account account name from env, or account id/account alias from boto3
    account_name = os.environ.get("AWS_ACCOUNT_NAME", None)
    if account_name is None:
        iam = boto3.client("iam")
        paginator = iam.get_paginator("list_account_aliases")
        for aliases in paginator.paginate(PaginationConfig={"MaxItems": 1}):
            if "AccountAliases" in aliases and len(aliases["AccountAliases"]) > 0:
                account_name = aliases["AccountAliases"][0]

    if account_name is None:
        account_name = boto3.client("sts").get_caller_identity().get("Account")

    if account_name is None:
        account_name = "[NOT FOUND]"

    return account_name


def find_by_key(values: list, key: str, value: str):
    for item in values:
        if item.get(key) == value:
            return item
    return None


def get_secret(secret_identifier):
    """
    Get secret value from AWS Secrets Manager.

    Args:
        secret_identifier: Can be either:
            - Secret name (e.g., 'my-secret')
            - Full ARN (e.g., 'arn:aws:secretsmanager:us-east-1:123456789012:secret:my-secret-ABC123')
            - Partial ARN (e.g., 'us-east-1:123456789012:secret:my-secret')

    Returns:
        str: The secret value
    """
    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager')
    get_secret_value_response = client.get_secret_value(SecretId=secret_identifier)
    return get_secret_value_response['SecretString']


def lambda_handler(event, context):
    group_by = os.environ.get("GROUP_BY", "SERVICE")
    length = int(os.environ.get("LENGTH", "5"))
    cost_aggregation = os.environ.get("COST_AGGREGATION", "UnblendedCost")
    mover_min_usd = float(os.environ.get("MOVER_MIN_USD", "0.5"))
    budget_name = os.environ.get("BUDGET_NAME")

    report = build_report(group_by=group_by, length=length, cost_aggregation=cost_aggregation, mover_min_usd=mover_min_usd, budget_name=budget_name)
    summary, buffer = report["summary"], render_text(report)

    slack_hook_url = None
    slack_secret_id = os.environ.get('SLACK_WEBHOOK_SECRET_ID')
    if slack_secret_id:
        slack_hook_url = get_secret(slack_secret_id)
    else:
        slack_hook_url = os.environ.get('SLACK_WEBHOOK_URL')

    if slack_hook_url:
        publish_slack(slack_hook_url, summary, buffer, render_blocks(report))

    teams_hook_url = os.environ.get('TEAMS_WEBHOOK_URL')
    if teams_hook_url:
        publish_teams(teams_hook_url, summary, buffer)

    google_hook_url = os.environ.get('GOOGLE_WEBHOOK_URL')
    if google_hook_url:
        publish_google(google_hook_url, summary, buffer)

def report_cost(group_by: str = "SERVICE", length: int = 5, cost_aggregation: str = "UnblendedCost", result: dict = None, today: str = None, account_name: str = None, mover_min_usd: float = 0.5):
    """
    The report as (summary line, monospace table, cost per day by item) --
    the plain-text form, used by Teams, Google Chat and the Slack fallback.
    """
    report = build_report(group_by=group_by, length=length, cost_aggregation=cost_aggregation, result=result, today=today, account_name=account_name, mover_min_usd=mover_min_usd)
    return report["summary"], render_text(report), report["data"]


def build_report(group_by: str = "SERVICE", length: int = 5, cost_aggregation: str = "UnblendedCost", result: dict = None, today: str = None, account_name: str = None, mover_min_usd: float = 0.5, monthly_result: dict = None, budget_name: str = None, budget: dict = None):
    """
    Build the report for the n_days days before `today`, as data: the
    render_* functions turn it into a message.

    Rows are the `length` most expensive items yesterday, plus any item whose
    cost moved by at least `mover_min_usd` against its baseline -- so a service
    that dropped to $0 is listed instead of vanishing into "Other".

    Args:
        result: a GetCostAndUsage response to report on instead of querying
            Cost Explorer (used by the tests)
        monthly_result: the same for the daily totals behind the month
            summary. When `result` is given and this is not, the month
            summary is left out rather than queried.
        budget_name: the AWS Budget to show; budget: its DescribeBudget
            'Budget', to skip the lookup (tests)
        today: 'YYYY-MM-DD'; defaults to the current UTC date. Computed per
            call, not at import time, so a warm Lambda container never
            reports a stale window.
        account_name: skips the account name lookup when given
    """
    if today is None:
        today = datetime.datetime.now(datetime.timezone.utc).date()
    else:
        today = datetime.datetime.strptime(today, '%Y-%m-%d').date()

    # Generate list of dates, so that even if our data is sparse,
    # we have the correct length lists of costs (len is n_days)
    week_ago, yesterday, list_of_dates = date_window(today)
    print(yesterday)
    print(list_of_dates)

    if account_name is None:
        account_name = get_account_name()

    query = {
        "TimePeriod": {
            "Start": week_ago.strftime('%Y-%m-%d'),
            "End": today.strftime('%Y-%m-%d'),
        },
        "Granularity": "DAILY",
        "Filter": {
            "Not": {
                "Dimensions": {
                    "Key": "RECORD_TYPE",
                    "Values": excluded_record_types,
                }
            }
        },
        "Metrics": [cost_aggregation],
        "GroupBy": [
            {
                "Type": "DIMENSION",
                "Key": group_by,
            },
        ],
    }

    # Only run the query when on lambda, not when testing locally with a fixture
    if result is None:
        result = boto3.client('ce').get_cost_and_usage(**query)
        if monthly_result is None:
            # Ungrouped daily totals from the start of last month: one more
            # request, a single page (at most 62 rows).
            monthly_query = {k: v for k, v in query.items() if k != "GroupBy"}
            monthly_query["TimePeriod"] = {
                "Start": month_window(yesterday)[0].strftime('%Y-%m-%d'),
                "End": today.strftime('%Y-%m-%d'),
            }
            monthly_result = boto3.client('ce').get_cost_and_usage(**monthly_query)

    cost_per_day_by_service = defaultdict(list)

    # First create a dict of dicts, then loop over the services and over
    # list_of_dates, so that even for sparse data we get a full list of costs
    cost_per_day_dict = defaultdict(dict)

    for day in result['ResultsByTime']:
        start_date = day["TimePeriod"]["Start"]
        for group in day['Groups']:
            key = group['Keys'][0]
            if group_by == "LINKED_ACCOUNT":
                dimension = find_by_key(result["DimensionValueAttributes"], "Value", key)
                if dimension:
                    key += " ("+dimension["Attributes"]["description"]+")"
            cost = float(group['Metrics'][cost_aggregation]['Amount'])
            cost_per_day_dict[key][start_date] = cost

    for key in cost_per_day_dict.keys():
        for start_date in list_of_dates:
            cost = cost_per_day_dict[key].get(start_date, 0.0)  # fallback for sparse data
            cost_per_day_by_service[key].append(cost)

    # Sort the map by yesterday's cost
    most_expensive_yesterday = sorted(cost_per_day_by_service.items(), key=lambda i: i[1][-1], reverse=True)

    visible = [(name, costs) for name, costs in most_expensive_yesterday if not is_negligible(costs)]
    rows = [
        (name, costs) for rank, (name, costs) in enumerate(visible)
        # the unrounded change: a $0.495 move must not pass a $0.50 threshold
        if rank < length or abs(costs[-1] - baseline(costs)) >= mover_min_usd
    ]
    row_names = {name for name, _ in rows}
    folded = [(name, costs) for name, costs in most_expensive_yesterday if name not in row_names]

    other_costs = [0.0] * n_days
    for service_name, costs in folded:
        for i, cost in enumerate(costs):
            other_costs[i] += cost

    total_costs = [0.0] * n_days
    for service_name, costs in most_expensive_yesterday:
        for i, cost in enumerate(costs):
            total_costs[i] += cost

    noun = "services" if group_by == "SERVICE" else "items"
    other_label = f"Other ({len(folded)} {noun})"

    # Shorten names only while that keeps every row distinct
    names = {name: name for name, _ in rows}
    if group_by == "SERVICE" and len({short_name(name) for name in names}) == len(names):
        names = {name: short_name(name) for name in names}

    def row(label, costs, kind):
        usd, pct = delta(costs)
        return {"name": label, "kind": kind, "yday": costs[-1], "usd": usd, "pct": pct,
                "spark": sparkline(costs[-spark_days:])}

    table = [row(names[name], costs, "item") for name, costs in rows]
    if folded:
        table.append(row(other_label, other_costs, "other"))
    table.append(row("Total", total_costs, "total"))

    cost_per_day_by_service["total"] = total_costs[-1]

    yesterday_label = f"{yesterday:%Y-%m-%d}, partial"

    # The Lambda runs in the management (payer) account, where Cost Explorer
    # returns the consolidated bill: REPORT_SCOPE says so in the summary.
    scope = os.environ.get("REPORT_SCOPE")
    report_for = f"{scope} ({account_name})" if scope else f"account {account_name}"

    credits_expire_date = os.environ.get('CREDITS_EXPIRE_DATE')
    if credits_expire_date:
        credits_expire_date = datetime.datetime.strptime(credits_expire_date, "%m/%d/%Y")

        credits_remaining_as_of = os.environ.get('CREDITS_REMAINING_AS_OF')
        credits_remaining_as_of = datetime.datetime.strptime(credits_remaining_as_of, "%m/%d/%Y")

        credits_remaining = float(os.environ.get('CREDITS_REMAINING'))

        days_left_on_credits = (credits_expire_date - credits_remaining_as_of).days
        allowed_credits_per_day = credits_remaining / days_left_on_credits

        relative_to_budget = (total_costs[-1] / allowed_credits_per_day) * 100.0

        if relative_to_budget < 60:
            emoji = ":white_check_mark:"
        elif relative_to_budget > 110:
            emoji = ":rotating_light:"
        else:
            emoji = ":warning:"

        credit_line = (f"{emoji} {relative_to_budget:.2f}% of the credit budget "
                       f"${allowed_credits_per_day:,.2f} for the day")
        summary = (f"{emoji} Yesterday's cost ({yesterday_label}) for {report_for} ${total_costs[-1]:,.2f} "
                   f"is {relative_to_budget:.2f}% of credit budget "
                   f"${allowed_credits_per_day:,.2f} for the day."
                  )
    else:
        credit_line = None
        summary = f"Yesterday's cost ({yesterday_label}) for {report_for} was ${total_costs[-1]:,.2f}"

    month = None
    if monthly_result is not None:
        month = month_summary({
            day["TimePeriod"]["Start"]: float(day["Total"][cost_aggregation]["Amount"])
            for day in monthly_result["ResultsByTime"]
        }, yesterday)

    if budget is None and budget_name:
        budget = get_budget(budget_name)

    month_lines = []
    if month:
        month_lines.append(
            f"{month['month']:%B} to date: {money(month['month_to_date'])} · "
            f"same point in {month['last_month']:%B} {money(month['last_month_to_date'])} ({month['pct']}) · "
            f"on pace for {money(month['pace'])}")
    if budget:
        month_lines.append(budget_line(budget))

    return {
        "summary": summary,
        "date": yesterday,
        "report_for": report_for,
        "credit_line": credit_line,
        "month": month,
        "month_lines": month_lines,
        "rows": table,
        "footer": footer(cost_aggregation),
        "data": cost_per_day_by_service,
    }


def render_text(report):
    """The table as monospace text."""
    rows = report["rows"]
    width = max(len(r["name"]) for r in rows + [{"name": "Service"}])

    buffer = "".join(line + "\n" for line in report["month_lines"])
    if buffer:
        buffer += "\n"
    buffer += f"{'Service':{width}} ${'Yday*':8} {'∆$':>8} {'∆%':>5} Last {spark_days}d\n"
    for r in rows:
        buffer += f"{r['name']:{width}} ${r['yday']:8,.2f} {r['usd']:+8,.2f} {r['pct']:>5} {r['spark']}\n"
    buffer += "\n" + report["footer"]
    return buffer


def money(usd: float, sign: bool = False):
    """$1,234.50, or with sign=True +$1.27 / -$0.40."""
    if not sign:
        return f"${usd:,.2f}"
    return f"{'-' if usd < 0 else '+'}${abs(usd):,.2f}"


def render_blocks(report):
    """
    The report as a Slack Block Kit message: header, summary, table, footer.
    The top-level `text` is what notifications and screen readers show.
    """
    total = report["rows"][-1]

    def cell(text, bold=False):
        if not bold:
            return {"type": "raw_text", "text": text}
        return {"type": "rich_text", "elements": [{"type": "rich_text_section", "elements": [
            {"type": "text", "text": text, "style": {"bold": True}}]}]}

    header = ["Service", "Yday*", "∆$", "∆%", f"Last {spark_days}d"]
    rows = [[cell(text, bold=True) for text in header]]
    for r in report["rows"]:
        rows.append([
            cell(r["name"], bold=r["kind"] != "item"),
            cell(money(r["yday"])),
            cell(money(r["usd"], sign=True)),
            cell(r["pct"]),
            cell(r["spark"]),
        ])

    summary = (f"*{money(total['yday'])}* yesterday · ∆ {money(total['usd'], sign=True)} ({total['pct']}) "
               f"vs. the {baseline_days}-day average\n"
               f"For {report['report_for']}")
    if report["credit_line"]:
        summary += "\n" + report["credit_line"]
    for line in report["month_lines"]:
        summary += "\n" + line

    return {
        "text": report["summary"],
        "blocks": [
            {"type": "header", "text": {"type": "plain_text", "text": f"AWS cost · {report['date']:%Y-%m-%d} (partial)"}},
            {"type": "section", "text": {"type": "mrkdwn", "text": summary}},
            {"type": "table",
             "column_settings": [{"is_wrapped": True}] + [{"align": "right"}] * 3 + [{"align": "left"}],
             "rows": rows},
            {"type": "context", "elements": [
                {"type": "plain_text", "text": text} for text in report["footer"].splitlines()]},
        ],
    }


def post_json(url, payload, timeout=5):
    """
    POST a JSON payload using only the standard library, so the function
    has no third-party dependencies to package.

    Returns:
        tuple: (HTTP status code, response body)
    """
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()


def publish_slack(hook_url, summary, buffer, blocks_payload=None):
    """
    Post the Block Kit message; if Slack rejects it, post the plain-text
    report instead, so a layout error never costs the day's report.
    """
    if blocks_payload:
        status, body = post_json(hook_url, blocks_payload)
        if status == 200:
            return
        print("HTTP %s: %s -- retrying as plain text" % (status, body))

    status, body = post_json(
        hook_url,
        {
            "text": summary + "\n\n```\n" + buffer + "\n```",
        }
    )

    if status != 200:
        print("HTTP %s: %s" % (status, body))


def publish_teams(hook_url, summary, buffer):

    status, body = post_json(
        hook_url,
        {
            "text": summary + "\n\n```\n" + buffer + "\n```",
        }
    )

    if status != 200:
        print("HTTP %s: %s" % (status, body))

def publish_google(hook_url, summary, buffer):

    message = {
        "text": summary + "\n\n```\n" + buffer + "\n```"
    }

    status, body = post_json(hook_url, message)

    if status != 200:
        print("HTTP %s: %s" % (status, body))
