# AGENTS.md: aws-batch-demoapp layer

Guidance for AI agents working on this layer. Human docs (features, examples, verification): `README.md`.
Repository-wide rules: root `CLAUDE.md` / `AGENTS.md`.

## Scope

- Layer path: `apps-devstg/us-east-1/aws-batch-demoapp`. State key: `apps-devstg/aws-batch-demoapp/terraform.tfstate`.
- Purpose: AWS Batch reference deployment (AWS "Hello World" sample by default). Everything is parametrized.
  Do not hardcode values in `.tf` files. Add or extend variables in `variables.tf` instead.
- Resource name prefix: `local.name` = `bb-devstg-batch-demoapp`.

## File map

| File | Contents |
| --- | --- |
| `config.tf` | Provider, backend, remote state: `vpc` (base-network), `keys` (security-keys), `notifications` (count-gated) |
| `variables.tf` | All inputs. `compute_type` is the Fargate/EC2 switch |
| `locals.tf` | Derived flags (`is_fargate`, `is_ec2`, `is_spot`), AMI type, subnets, secret ARN parsing, **container properties JSON per job definition** |
| `batch.tf` | `terraform-aws-modules/batch/aws` 3.0.3: compute environment `main`, job queue `main`, job definitions |
| `launch_template.tf` | EC2/SPOT only (`count`): encrypted root volume, IMDSv2 |
| `network.tf` | Egress-only security group |
| `iam.tf` | Execution role (+ secrets policy), job role (+ S3/KMS policy, managed policies) |
| `logs.tf` | `/aws/batch/<name>` log group |
| `eventbridge.tf` | `terraform-aws-modules/eventbridge/aws` 4.4.1: Scheduler schedules (universal target `aws-sdk:batch:submitJob`) and failure rule → SNS |
| `outputs.tf` | ARNs/names for queue, job definitions, roles, log group, schedules |

## Invariants (do not break)

1. **Job definitions follow `compute_type`.** `platform_capabilities`, `networkConfiguration`,
   `fargatePlatformConfiguration`, `runtimePlatform` and `ephemeralStorage` are added only for Fargate in
   `local.container_properties`. Keep that logic in one place.
2. **Do not emit empty or null keys in `container_properties`.** The AWS provider normalizes the JSON, and empty
   arrays or nulls cause a perpetual diff. Use the `merge(..., cond ? {...} : {})` pattern.
3. **The compute environment uses `name_prefix`**, not `name`. The module sets `create_before_destroy`, and
   switching `compute_type` replaces the environment. A fixed name would clash.
4. **Compute environment `compute_resources.tags` only for EC2.** Tag changes replace the environment, and
   Fargate does not accept them (the module drops them).
5. **Service role:** `create_service_iam_role = false` means the Batch service-linked role is used. Do not
   switch to the legacy `AWSBatchServiceRole` without a reason.
6. **Schedule input is PascalCase** (`JobName`, `JobQueue`, `JobDefinition`, `ContainerOverrides.Command`,
   `Environment[].Name/Value`). `JobDefinition` is the **name without revision**, so CI-registered revisions are
   picked up. Do not switch it to the ARN.
7. **The scheduler role is scoped** to the queue ARN and `job-definition/<name>:*` of the definitions referenced
   by `schedules`. Keep it least privilege.
8. **The eventbridge module uses the `default` bus** with `create_bus = false` and
   `create_log_delivery[_source] = false`. The module defaults would add log delivery to the shared default
   bus. Keep them off.
9. **The failure rule filters on this layer's queue ARN.** It targets the `workload-monitoring` topic of the
   `notifications` layer (`sns_topic_arn_workload_monitoring`), whose topic policy there allows
   `events.amazonaws.com`. Do not add an `aws_sns_topic_policy` here: only one policy can exist per topic.
   Do not point it to the other monitoring topics, which have no EventBridge permission.
10. **Tags:** `local.tags` includes `"aws-apn-id" = local.prm_apn_id`. Never hardcode a `pc:` code (`make prm-tags`).
11. **No pipeline IAM role in this layer** (agreed scope). CI/CD is documented in `README.md`.

## Decisions already made (do not re-ask)

- Default backend: `FARGATE`. GPU is opt-in (`ec2_config.gpu_enabled`, `ECS_AL2023_NVIDIA`).
- Default subnets: `private`. Egress (NAT or VPC endpoints) is a documented prerequisite, not created here.
- Root EBS: encrypted with `aws/ebs` by default. The account CMK needs key policy changes for the Auto Scaling
  and EC2 Spot service-linked roles (README prerequisite 5).
- IMDSv2 required, hop limit 1 by default.

## Validate changes

```bash
cd apps-devstg/us-east-1/aws-batch-demoapp
../../../.venv/bin/leverage tofu format
../../../.venv/bin/leverage tofu validate
# Offline alternative (no AWS credentials): tofu init -backend=false && tofu validate
../../../.venv/bin/leverage tofu plan   # needs SSO credentials (leverage aws sso login)
```

- If you change the module versions, regenerate `.terraform.lock.hcl` for
  `linux_amd64 linux_arm64 darwin_amd64 darwin_arm64` (see root `CLAUDE.md`).
- Before posting a plan to a PR, follow the redaction procedure in the root `CLAUDE.md`. **Never apply from automation.**
- When a change touches `notifications`, plan that layer too, since this layer depends on its topic policy.

## Common change recipes

- **New job definition field:** add `optional(...)` to the `job_definitions` object type, map it in
  `local.container_properties` (conditional merge), document it in the variable description and in `README.md`.
- **New compute option (EC2):** add it to `ec2_config`, wire it in `batch.tf` `compute_resources` or in
  `launch_template.tf`.
- **New notification state:** users set `failure_notifications.statuses`. No code change is needed.
- **Fargate on ARM64:** `cpu_architecture = "ARM64"` per job definition (the image must be arm64).
