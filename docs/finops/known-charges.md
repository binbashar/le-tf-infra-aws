# Known / expected charges

Recurring charges the team has already confirmed are expected. Read as **Phase 0**
of every `/aws-finops-investigate` run.

A bill line matches a row when its Cost Explorer `SERVICE` name **contains** the
**Match** text (case-insensitive) and — if the row names an account — it is billed
into that account.

A matched charge is described as *expected* instead of being raised as a finding, a
"biggest mover", or an anomaly. It is **still counted** in every total, account
breakdown and forecast. The allow-list changes how a charge is *described*, never
whether it is *counted*.

**No dollar amounts here, on purpose.** With no documented figure to rubber-stamp,
the skill compares a matched charge against its own recent months — so a known
charge that doubles still gets flagged as coming in higher than usual.

| Match | Account | Cadence | What it is |
| --- | --- | --- | --- |
| `Drata` | management | Monthly (mid-month) | Compliance-automation SaaS bought through AWS Marketplace. Bills to the payer account, so it lands as management-account spend rather than against the workload accounts that benefit from it. |
| `Partner Network` | management | Annual (March) | AWS Partner Network annual program fee. One large line every March; not a spike. |

## Maintaining this file

Add a row whenever an investigation flags something the team decides is expected and
recurring. Delete a row when the charge stops (a cancelled subscription left in the
list silently suppresses nothing, but it does mislead the next reader).

**Confirm the Match string against a report.** These are substrings of the Cost
Explorer `SERVICE` name, not product names — Marketplace sellers in particular can
appear under a legal entity name. If a run still flags a charge listed here, widen or
correct the Match text using the exact service name printed in that report.
