# Accepted exceptions

Spend the team has **reviewed and consciously accepted**: Multi-AZ kept on a
production database, a reserved capacity floor, a deliberately over-provisioned node
pool. Read as **Phase 0** of every `/aws-finops-optimize` run.

A matched finding is dropped from the Prioritised Action Plan and the priority tables
so each run stays about *new* opportunities. Suppression changes only whether an item
is *recommended* — matched spend is **still counted** in every total.

**The Baseline column is what makes suppression safe.** If an accepted item grows
materially past its baseline, the skill surfaces it in *Investigation Notes* as
*"accepted, now growing"* with the old and new figures, instead of hiding a
ballooning cost.

| Account | Service / Resource | What's accepted | Reason | Baseline ($/mo) | Revisit |
| --- | --- | --- | --- | --- | --- |
| _(none yet)_ | | | | | |

## Maintaining this file

Seeded empty on purpose: the first `/aws-finops-optimize` run should report
**everything**, and only findings the team then decides to live with belong here.
Adding rows pre-emptively suppresses opportunities nobody has looked at yet.

When you add one, fill in every column — a row without a **Baseline** cannot trigger
the "accepted, now growing" escape hatch, and a row without a **Revisit** date is an
exception that quietly becomes permanent.
