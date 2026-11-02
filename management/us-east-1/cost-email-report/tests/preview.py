"""
Render the report for the sample organization to an HTML file, to see the
email without AWS access. From the layer directory:

    python3 tests/preview.py [output.html]   # default: /tmp/cost-email-report-preview.html
"""
import pathlib
import sys

LAYER = pathlib.Path(__file__).resolve().parent.parent
sys.dont_write_bytecode = True
sys.path.insert(0, str(LAYER / "src"))
sys.path.insert(0, str(LAYER / "tests"))

import report  # noqa: E402
import sample  # noqa: E402

out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp/cost-email-report-preview.html")
months = report.report_months(sample.TODAY)
data = report.build_report(sample.CONFIG, sample.TODAY, months, sample.costs(), sample.record_types(),
                           sample.ACCOUNTS, sample.EXTRAS)
out.write_text(f"<!doctype html><meta charset=utf-8><title>{report.subject(data)}</title>{report.render_html(data)}")
print(f"{report.subject(data)}\n{out}")
