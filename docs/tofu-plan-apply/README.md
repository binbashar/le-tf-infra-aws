# OpenTofu plan and apply on pull requests

GitOps for this repository's OpenTofu layers: every PR that touches an allowlisted layer gets a
reviewed plan, and onboarded layers are applied from the PR with `/tofu apply` before merge.

| Document | Read it to |
| --- | --- |
| [`tofu-plan.md`](tofu-plan.md) | Understand and operate the plan check (`OpenTofu Plan`), and add a layer to it |
| [`tofu-apply.md`](tofu-apply.md) | Apply a PR with `/tofu apply`, understand the gates, the lock, and the required `OpenTofu Apply` status, and onboard a layer |
| [`tofu-ci-incident.md`](tofu-ci-incident.md) | Stop the workflows and revoke their AWS credentials in an incident |
| [`tofu-plan-history.md`](tofu-plan-history.md) | See how both were rolled out: runs, supervised tests, lessons, and decisions |

Code lives in [`@bin/scripts/tofu_plan_ci/`](../../@bin/scripts/tofu_plan_ci/), and the workflows
in [`.github/workflows/`](../../.github/workflows/) (`tofu-plan.yml`, `tofu-apply.yml`,
`tofu-apply-status.yml`).
