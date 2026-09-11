# CLAUDE.md

Guidance for Claude Code when working in this layer.

## Layer Overview

Provisions the IaC-able foundation for the AWS FinOps Agent (preview) in the management account: two IAM roles (`finops-agent.amazonaws.com` trust) and inline permission policies mirroring the AWS setup guide. The agentspace itself is created manually via the console wizard (preview API only — no CFN/awscc/CDK/tofu resource exists).

## Gotchas

- **`${aws:PrincipalAccount}` must be escaped as `$${aws:PrincipalAccount}`** inside the `jsonencode` policy blocks in `iam.tf` — it is an IAM policy variable, not a Terraform reference.
- **Inline vs managed policies:** policies are intentionally inline (preview stability + git visibility). See README for the managed-policy switch.
- **Provider `aws ~> 5.0`**, not 6.x (see repo CLAUDE.md re: Apple Silicon Rosetta hang on 6.x).
- **The agent's cost telemetry is not provisioned here.** The anomaly monitor lives in `management/global/cost-mgmt` and the org-wide Compute Optimizer enrollment in `management/global/organizations` — they are shared FinOps prerequisites, not agent-specific. Do not re-add them here: `aws_computeoptimizer_enrollment_status` is an account-level singleton and two layers would fight over it.
- **Offline validate:** `tofu init -backend=false && tofu validate` (native tofu, no SSO). Full `leverage tofu plan` needs SSO.

## Manual post-apply step

Create the agentspace in the console selecting the `agent_role_arn` (Step 2) and `operator_role_arn` (Step 3) outputs. See README.
