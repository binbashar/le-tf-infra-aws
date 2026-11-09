"""
Sample data shared by the tests and preview.py: an organization with three
accounts, reported on 2026-11-05 for October 2026. Account ids are fake.
"""
import datetime
from decimal import Decimal

TODAY = datetime.date(2026, 11, 5)
SEPTEMBER, OCTOBER = "2026-09-01", "2026-10-01"

ACCOUNTS = {"111111111111": "management", "222222222222": "apps-prd", "333333333333": "apps-devstg"}

# {month: {(account, service): cost}}, credits excluded, as Cost Explorer groups them
COSTS = {
    SEPTEMBER: {
        ("222222222222", "Amazon Elastic Compute Cloud - Compute"): "120.00",
        ("222222222222", "Amazon Relational Database Service"): "80.00",
        ("222222222222", "Amazon Redshift"): "45.00",  # dropped to $0 in October
        ("333333333333", "Amazon Elastic Compute Cloud - Compute"): "60.00",
        ("333333333333", "Amazon Simple Storage Service"): "10.00",
        ("111111111111", "Drata Security & Compliance Automation Platform"): "625.00",
        ("111111111111", "AWS Cost Explorer"): "40.00",
    },
    OCTOBER: {
        ("222222222222", "Amazon Elastic Compute Cloud - Compute"): "190.00",
        ("222222222222", "Amazon Relational Database Service"): "80.40",
        ("333333333333", "Amazon Elastic Compute Cloud - Compute"): "55.00",
        ("333333333333", "Amazon Simple Storage Service"): "10.20",
        ("333333333333", "Amazon Bedrock"): "25.00",  # new in October
        ("111111111111", "Drata Security & Compliance Automation Platform"): "625.00",
        ("111111111111", "AWS Cost Explorer"): "54.00",
    },
}

# {month: {record type: cost}}: the invoice lines, credits included
RECORD_TYPES = {
    SEPTEMBER: {"Usage": "355.00", "Other": "625.00", "Credit": "-300.00", "Tax": "0.00"},
    OCTOBER: {"Usage": "414.60", "Other": "625.00", "Credit": "-320.00", "Tax": "0.00"},
}


def ce_groups(month_costs, keys_of=lambda key: list(key)):
    return [{"Keys": keys_of(key), "Metrics": {"UnblendedCost": {"Amount": amount, "Unit": "USD"}}}
            for key, amount in month_costs.items()]


def costs():
    return {month: {key: Decimal(v) for key, v in rows.items()} for month, rows in COSTS.items()}


def record_types():
    return {month: {key: Decimal(v) for key, v in rows.items()} for month, rows in RECORD_TYPES.items()}


EXTRAS = {
    "forecast": {"month": datetime.date(2026, 11, 1), "month_to_date": Decimal("150.00"), "forecast": Decimal("1080.00")},
    "budget": {"name": "monthly", "limit": Decimal("750"), "actual": Decimal("1039.60"), "forecast": Decimal("1080")},
    "anomalies": [{"start": "2026-10-12", "impact": Decimal("64.20"), "service": "Amazon Elastic Compute Cloud - Compute",
                   "account": "222222222222", "feedback": ""}],
    "sp_coverage": {"percentage": Decimal("0"), "on_demand": Decimal("245.00")},
    "untagged": {"tag_key": "Project", "untagged": Decimal("120.00"), "total": Decimal("1039.60")},
    "credits": {"balances": {"USD": Decimal("2450.00")}, "expires": datetime.date(2027, 3, 31)},
}

CONFIG = {
    "organization": "Example Org",
    "sender": "FinOps <finops@example.com>",
    "recipients": ["cfo@example.com", "devops@example.com"],
    "binbash_recipients": [],
    "binbash_until": "",
    "account_id": "111111111111",
    "budget_name": "monthly",
    "change_min_usd": Decimal("1"),
    "top_n": 3,
    "anomaly_min_usd": Decimal("10"),
    "untagged_tag_key": "Project",
}
