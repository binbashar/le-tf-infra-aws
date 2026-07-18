# CLAUDE.md

Guidance for Claude Code when working in this layer.

## Layer Overview

Provisions the IaC-able foundation for the AWS FinOps Agent (preview) in the management account: two IAM roles (`finops-agent.amazonaws.com` trust), inline permission policies mirroring the AWS setup guide, a SERVICE cost anomaly monitor, and Compute Optimizer opt-in (management account only). The agentspace itself is created manually via the console wizard (preview API only — no CFN/awscc/CDK/tofu resource exists).

## Gotchas

- **`${aws:PrincipalAccount}` must be escaped as `$${aws:PrincipalAccount}`** inside the `jsonencode` policy blocks in `iam.tf` — it is an IAM policy variable, not a Terraform reference.
- **Inline vs managed policies:** policies are intentionally inline (preview stability + git visibility). See README for the managed-policy switch.
- **Provider `aws ~> 5.0`**, not 6.x (see repo CLAUDE.md re: Apple Silicon Rosetta hang on 6.x). Both `aws_ce_anomaly_monitor` and `aws_computeoptimizer_enrollment_status` exist in 5.100.
- **`aws_computeoptimizer_enrollment_status` takes no `tags`** and is gated behind `var.enable_compute_optimizer`.
- **Offline validate:** `tofu init -backend=false && tofu validate` (native tofu, no SSO). Full `leverage tofu plan` needs SSO.

## Manual post-apply step

Create the agentspace in the console selecting the `agent_role_arn` (Step 2) and `operator_role_arn` (Step 3) outputs. See README.
