"""
Print the report built from live Cost Explorer data, without posting it.

Each run is two GetCostAndUsage requests ($0.02). Run it through
`make cost-report-preview`, which loads the management account's Leverage
profile; LENGTH, GROUP_BY, COST_AGGREGATION, MOVER_MIN_USD, REPORT_SCOPE and
BUDGET_NAME mirror the Lambda's env vars.

The Block Kit message is checked with Slack's public blocks.validate method
(no token; it sends the payload to Slack, the report's destination anyway)
and printed as a Block Kit Builder link to preview it.
"""
import json
import os
import pathlib
import sys
import urllib.parse
import urllib.request

# src/ is zipped as-is into the Lambda package: keep __pycache__ out of it.
sys.dont_write_bytecode = True
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "src"))

import handler  # noqa: E402

report = handler.build_report(
    group_by=os.environ.get("GROUP_BY", "SERVICE"),
    length=int(os.environ.get("LENGTH", "20")),
    cost_aggregation=os.environ.get("COST_AGGREGATION", "UnblendedCost"),
    mover_min_usd=float(os.environ.get("MOVER_MIN_USD", "0.5")),
    budget_name=os.environ.get("BUDGET_NAME"),
)
print()
print(report["summary"])
print()
print(handler.render_text(report))

payload = handler.render_blocks(report)
request = urllib.request.Request(
    "https://slack.com/api/blocks.validate",
    data=urllib.parse.urlencode({"blocks": json.dumps(payload["blocks"])}).encode(),
)
with urllib.request.urlopen(request, timeout=10) as response:
    print("blocks.validate:", response.read().decode())

builder = json.dumps({"blocks": payload["blocks"]}, separators=(",", ":"))
print("Block Kit Builder:", "https://app.slack.com/block-kit-builder#" + urllib.parse.quote(builder))
