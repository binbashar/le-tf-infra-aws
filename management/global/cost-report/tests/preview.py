"""
Print the report built from live Cost Explorer data, without posting it.

Each run is two GetCostAndUsage requests and one GetAnomalies ($0.02-0.03). Run it through
`make cost-report-preview`, which loads the management account's Leverage
profile; LENGTH, GROUP_BY, COST_AGGREGATION, MOVER_MIN_USD, REPORT_SCOPE,
BUDGET_NAME, ALERT_*, DAILY_MODE, FULL_REPORT_WEEKDAY and ANOMALY_DAYS mirror the Lambda's env
vars; MODE=full|compact stands in for the invocation's {"mode": ...}.

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
    alert_min_usd=float(os.environ.get("ALERT_MIN_USD", "1")),
    alert_min_pct=float(os.environ.get("ALERT_MIN_PCT", "30")),
    anomaly_days=int(os.environ.get("ANOMALY_DAYS", "14")),
)
mode = handler.report_mode(report, os.environ.get("MODE"), os.environ.get("DAILY_MODE", "full"),
                           int(os.environ.get("FULL_REPORT_WEEKDAY", "0")))
print()
print(f"Today's mode: {mode} ({len(report['alerts'])} alerts, {len(report['anomalies'] or [])} anomalies). Both forms follow.")
print()
print("--- compact ---")
print(handler.compact_line(report))
print()
print("--- full ---")
print(report["summary"])
print()
print(handler.render_text(report))

for name, payload in (("compact", handler.render_compact_blocks(report)),
                      ("full", handler.render_blocks(report, os.environ.get("ALERT_MENTION", "")))):
    request = urllib.request.Request(
        "https://slack.com/api/blocks.validate",
        data=urllib.parse.urlencode({"blocks": json.dumps(payload["blocks"])}).encode(),
    )
    with urllib.request.urlopen(request, timeout=10) as response:
        print(f"blocks.validate ({name}):", response.read().decode())
    builder = json.dumps({"blocks": payload["blocks"]}, separators=(",", ":"))
    print(f"Block Kit Builder ({name}):", "https://app.slack.com/block-kit-builder#" + urllib.parse.quote(builder))
