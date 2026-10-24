"""
Print the report built from live Cost Explorer data, without posting it.

Each run is one GetCostAndUsage request ($0.01). Run it through
`make cost-report-preview`, which loads the management account's Leverage
profile; LENGTH, GROUP_BY and COST_AGGREGATION mirror the Lambda's env vars.
"""
import os
import pathlib
import sys

# src/ is zipped as-is into the Lambda package: keep __pycache__ out of it.
sys.dont_write_bytecode = True
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "src"))

import handler  # noqa: E402

summary, buffer, _ = handler.report_cost(
    group_by=os.environ.get("GROUP_BY", "SERVICE"),
    length=int(os.environ.get("LENGTH", "20")),
    cost_aggregation=os.environ.get("COST_AGGREGATION", "UnblendedCost"),
)
print()
print(summary)
print()
print(buffer)
