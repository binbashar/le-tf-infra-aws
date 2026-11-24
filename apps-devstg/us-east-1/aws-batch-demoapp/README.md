# AWS Batch Demo App

This layer deploys a complete, parametrized **AWS Batch** setup in the `apps-devstg` account. Out of the box it
runs the AWS Batch **"Hello World"** sample job from the
[AWS Batch getting started tutorials](https://docs.aws.amazon.com/batch/latest/userguide/Batch_GetStarted.html)
(`public.ecr.aws/amazonlinux/amazonlinux:latest` running `echo hello world`) on **Fargate**.

One variable, `compute_type`, switches the backend between **Fargate** and **managed EC2** (On-Demand or Spot,
with optional **GPU**). Everything else is also set through variables: job definitions, schedules, IAM
permissions, logging and notifications.

## Table of contents

- [What gets created](#what-gets-created)
- [Architecture](#architecture)
- [Official modules used](#official-modules-used)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Deploy](#deploy)
- [Verify](#verify)
- [Day-2 operations](#day-2-operations)
- [CI/CD: deploy pipeline for job definitions](#cicd-deploy-pipeline-for-job-definitions)
- [Troubleshooting](#troubleshooting)
- [Delivery tasks covered](#delivery-tasks-covered)
- [References](#references)

## What gets created

| Resource | When | File |
| --- | --- | --- |
| Batch compute environment (`FARGATE`, `FARGATE_SPOT`, `EC2` or `SPOT`) | always | `batch.tf` |
| Batch job queue linked to the compute environment | always | `batch.tf` |
| One Batch job definition per entry in `job_definitions` | always | `batch.tf` |
| Security group (egress only) for jobs / container instances | always | `network.tf` |
| Execution role (image pull, logs, secrets) | always | `iam.tf` |
| Job role (least privilege, S3/KMS grants from variables) | always | `iam.tf` |
| CloudWatch log group, KMS-encrypted, with a retention period | always | `logs.tf` |
| Launch template (encrypted root EBS, IMDSv2 required) | `EC2` / `SPOT` | `launch_template.tf` |
| Instance role + instance profile (ECS agent, ECR, Logs, optional SSM) | `EC2` / `SPOT` | `batch.tf` (module) |
| Spot fleet role | `SPOT` | `batch.tf` (module) |
| EventBridge Scheduler schedules + scheduler IAM role | `schedules` not empty | `eventbridge.tf` |
| EventBridge rule: job `FAILED` → Slack SNS topic | `failure_notifications.enabled` | `eventbridge.tf` |

Resources are named `bb-devstg-batch-demoapp[-<suffix>]`.

## Architecture

```text
                       EventBridge Scheduler                    EventBridge (default bus)
                     (cron / rate, per schedule)              rule: Batch Job State Change
                                 │ batch:SubmitJob                  status = FAILED, this queue
                                 ▼                                         │
 aws batch submit-job ──► Job queue ──► Compute environment               ▼
 (manual / CI)              │          FARGATE | FARGATE_SPOT       SNS workload-monitoring topic
                            │          EC2 | SPOT (+GPU AMI)               │
                            ▼                    │                         ▼
                     Job definitions             │                 notify-slack Lambda ──► Slack
                     image (ECR), vCPU/mem/GPU   │
                     env, secrets, retry,        ▼
                     timeout              private | public subnets (base-network VPC)
                            │
                            ├─► Execution role: ECR pull, Secrets Manager / SSM secrets
                            ├─► Job role: S3 / KMS (least privilege)
                            └─► CloudWatch Logs: /aws/batch/bb-devstg-batch-demoapp
```

### Dependencies (remote state)

| Layer | Used for |
| --- | --- |
| `apps-devstg/us-east-1/base-network` | VPC id, private / public subnets |
| `apps-devstg/us-east-1/security-keys` | KMS key for the log group |
| `apps-devstg/us-east-1/notifications` | `workload-monitoring` SNS topic (only when `failure_notifications.sns_topic_arn` is not set) |

## Official modules used

| Module | Version | Purpose |
| --- | --- | --- |
| [`terraform-aws-modules/batch/aws`](https://registry.terraform.io/modules/terraform-aws-modules/batch/aws) | 3.0.3 | Compute environment, job queue, job definitions, instance / spot fleet roles |
| [`terraform-aws-modules/eventbridge/aws`](https://registry.terraform.io/modules/terraform-aws-modules/eventbridge/aws) | 4.4.1 | Scheduler schedules, failure rule, scheduler IAM role |

The compute environment uses the AWS Batch **service-linked role** (`AWSServiceRoleForBatch`), not a custom service role.

## Prerequisites

1. **Network egress.** Jobs (and EC2 container instances) must reach ECR, CloudWatch Logs, ECS and, if used,
   Secrets Manager / SSM. In `apps-devstg` the NAT Gateway is **disabled** (`vpc_enable_nat_gateway = false` in
   `base-network`). Pick one:
   - **Private subnets (default, recommended):** enable the NAT Gateway in `base-network`, or add VPC endpoints
     (`ecr.api`, `ecr.dkr`, `s3` gateway, `logs`; plus `ecs`, `ecs-agent`, `ecs-telemetry` for EC2; plus
     `secretsmanager` / `ssm` if jobs use secrets; plus `ssm`, `ssmmessages`, `ec2messages` for Session Manager).
     **Public ECR images (`public.ecr.aws`, like the Hello World job) are not reachable through VPC endpoints**:
     use a NAT Gateway, or copy the image to a private ECR repository.
   - **Public subnets:** `subnets_tier = "public"`. With Fargate also set `assign_public_ip = true`. With EC2 the
     public subnets must auto-assign public IPs to instances (`map_public_ip_on_launch`), since Batch launches
     the instances.
2. **Slack notifications.** Apply `apps-devstg/us-east-1/notifications` **before** this layer. It creates the
   `workload-monitoring` SNS topic (output `sns_topic_arn_workload_monitoring`), whose policy lets EventBridge
   publish, and a notify-slack Lambda that posts with the monitoring webhook to `le-tools-monitoring`
   (variable `slack_channel_workload_monitoring`). Or point `failure_notifications.sns_topic_arn` to another
   topic that allows `events.amazonaws.com`.
3. **GPU (EC2 only).** Check the account's EC2 service quotas for the chosen GPU families, e.g.
   *Running On-Demand G and VT instances* and, with Spot, *All G and VT Spot Instance Requests*.
   **New accounts often start with a GPU vCPU quota of 0**: request increases before the engagement starts.
4. **Images.** Push application images to ECR (see the `shared/us-east-1/container-registry` layer). For
   cross-account pulls the ECR repository policy must allow the `apps-devstg` account.
5. **EBS encryption with the account CMK (optional).** Batch launches instances through the Auto Scaling /
   EC2 Spot service-linked roles, which cannot be granted access by IAM policies. To set
   `ec2_config.ebs_kms_key_arn` to the account CMK, first add a key policy statement (or grant) in
   `security-keys` for `AWSServiceRoleForAutoScaling` (and `AWSServiceRoleForEC2Spot` with Spot). Otherwise
   instances fail to launch. With the default (`null`) the root volume is still encrypted, with the AWS managed
   `aws/ebs` key.

## Configuration

All settings live in `variables.tf` (each variable documents its fields). Put environment-specific values in a
`*.auto.tfvars` file in this directory, e.g. `batch.auto.tfvars`.

| Variable | Default | What it controls |
| --- | --- | --- |
| `compute_type` | `FARGATE` | **Backend switch**: `FARGATE`, `FARGATE_SPOT`, `EC2`, `SPOT` |
| `max_vcpus` | `4` | Max vCPUs of the compute environment: *(jobs at the same time) × (vCPU per job)* |
| `subnets_tier` | `private` | `private` or `public` subnets of the account VPC |
| `assign_public_ip` | `false` | Fargate only: public IP for job tasks |
| `additional_security_group_ids` | `[]` | Extra security groups (e.g. to reach a database) |
| `ec2_config` | `{}` | EC2/SPOT: instance types, GPU, AMI type, root volume, IMDS, SSM, key pair |
| `compute_environment_update_policy` | `null` | Job timeout / termination on compute environment updates |
| `job_queue` | `{}` | Priority, state, actions for jobs stuck in `RUNNABLE` |
| `job_definitions` | Hello World | Image, command, vCPU, memory, GPU, env, secrets, timeout, retries |
| `job_role_permissions` | `{}` | S3 read / write buckets, KMS keys, managed policies for the job role |
| `log_retention_days` | `14` | Log group retention |
| `log_group_kms_encryption` | `true` | Encrypt the log group with the account KMS key |
| `schedules` | `{}` | EventBridge Scheduler schedules (cron / rate / at) |
| `failure_notifications` | enabled, `FAILED` | Job state notifications to Slack |

### Example: Fargate (default)

Nothing to set. To run the Hello World job in public subnets (no NAT Gateway):

```hcl
subnets_tier     = "public"
assign_public_ip = true
```

### Example: Fargate Spot, one job definition shared by several clients

```hcl
compute_type = "FARGATE_SPOT"
max_vcpus    = 8 # 4 jobs x 2 vCPU

job_definitions = {
  report = {
    image           = "<account_id>.dkr.ecr.us-east-1.amazonaws.com/<repo>:<tag>"
    command         = ["python", "report.py"]
    vcpu            = 2
    memory_mib      = 4096
    timeout_seconds = 7200
    retry_attempts  = 2
    environment     = { LOG_LEVEL = "info" }
    secrets = {
      DB_PASSWORD = "arn:aws:secretsmanager:us-east-1:<account_id>:secret:<name>"
    }
  }
}

job_role_permissions = {
  s3_read_bucket_arns  = ["arn:aws:s3:::<input-bucket>"]
  s3_write_bucket_arns = ["arn:aws:s3:::<output-bucket>"]
}

# One schedule per client, same job definition, different command
schedules = {
  client-a = {
    job_definition      = "report"
    schedule_expression = "cron(0 3 1 */3 ? *)" # quarterly, 03:00 UTC on day 1
    command             = ["python", "report.py", "--client", "a"]
  }
  client-b = {
    job_definition      = "report"
    schedule_expression = "cron(0 4 1 */3 ? *)"
    command             = ["python", "report.py", "--client", "b"]
  }
}
```

Fargate only accepts specific vCPU / memory combinations, see
[Fargate job definition resources](https://docs.aws.amazon.com/batch/latest/userguide/fargate.html).

### Example: managed EC2 with GPU

```hcl
compute_type = "EC2" # or "SPOT"
max_vcpus    = 8     # 2 jobs x 4 vCPU

ec2_config = {
  gpu_enabled          = true              # ECS_AL2023_NVIDIA AMI (NVIDIA driver + container toolkit)
  instance_types       = ["g4dn.xlarge"]   # sized to the GPU memory each job needs
  min_vcpus            = 0                 # scale to zero when idle
  root_volume_size_gib = 100               # large GPU images / datasets
}

job_definitions = {
  train = {
    image          = "<account_id>.dkr.ecr.us-east-1.amazonaws.com/<repo>:<tag>" # CUDA base image supported by the AMI driver
    command        = ["python", "train.py"]
    vcpu           = 4
    memory_mib     = 15000
    gpu            = 1
    retry_attempts = 3 # with SPOT, host terminations (interruptions) are retried, other failures are not
  }
}

job_queue = {
  job_state_time_limit_actions = {
    no_capacity = {
      max_time_seconds = 3600
      reason           = "CAPACITY:INSUFFICIENT_INSTANCE_CAPACITY"
    }
  }
}
```

The instance memory is not fully available to jobs (the ECS agent and OS reserve some), so ask for less than
the instance total (e.g. ~15 GiB on a 16 GiB `g4dn.xlarge`).

### Switching the backend

Changing `compute_type` replaces the compute environment (a new one is created first, `name_prefix` avoids
name clashes), updates the queue and registers new job definition revisions with the matching platform
capability. Let running jobs finish first, or set `compute_environment_update_policy`.

## Deploy

```bash
# 1. Dependencies first (once): base-network, security-keys, notifications (with EventBridge permission)
cd apps-devstg/us-east-1/notifications
leverage tofu plan && leverage tofu apply

# 2. This layer
cd ../aws-batch-demoapp
leverage tofu init
leverage tofu plan
leverage tofu apply
```

## Verify

The examples use the layer's outputs. Run them with the `apps-devstg` profile (e.g. `--profile bb-apps-devstg-devops`).

```bash
QUEUE=$(leverage tofu output -raw job_queue_name)
JOBDEF=bb-devstg-batch-demoapp-hello-world

# Submit a job manually and wait for SUCCEEDED
JOB_ID=$(aws batch submit-job --job-name hello-world-manual \
  --job-queue "$QUEUE" --job-definition "$JOBDEF" --query jobId --output text)
aws batch describe-jobs --jobs "$JOB_ID" --query 'jobs[0].[status,statusReason]'

# Read the output ("hello world")
aws logs tail /aws/batch/bb-devstg-batch-demoapp --since 15m
```

**GPU:** submit the GPU job with `--container-overrides '{"command":["nvidia-smi"]}'`. The log must list the
GPU. After the job ends, the compute environment scales back to `min_vcpus` (0): check
`aws batch describe-compute-environments`, and that no instances are left in EC2.

**Scheduler:** add a temporary schedule a few minutes ahead, apply, check the job runs, then remove it:

```hcl
schedules = {
  smoke-test = { job_definition = "hello-world", schedule_expression = "rate(5 minutes)" }
}
```

**Failure notification:** force a failed job and check the Slack channel of the `workload-monitoring` topic (`le-tools-monitoring` by default):

```bash
aws batch submit-job --job-name force-failure --job-queue "$QUEUE" --job-definition "$JOBDEF" \
  --container-overrides '{"command":["sh","-c","exit 1"]}'
```

## Day-2 operations

### Add a new job (e.g. a new client)

- **Same image, different arguments:** add a `schedules` entry that points to the existing job definition with
  its own `command` / `environment`. No new job definition is needed.
- **Different image or resources:** add an entry to `job_definitions` (and schedules if needed).
- Then `leverage tofu plan` / `apply`.

### Give jobs access to other resources

- **S3 / KMS:** `job_role_permissions.s3_read_bucket_arns`, `s3_write_bucket_arns`, `kms_key_arns`.
- **Other AWS APIs:** create a policy and add it to `job_role_permissions.managed_policy_arns`.
- **Databases / private endpoints:** allow the `security_group_id` output on the target security group, or add
  a security group in `additional_security_group_ids`.
- **Secrets:** add `secrets = { ENV_NAME = "<secret or parameter ARN>" }` to the job definition. The execution
  role gets read access to exactly those ARNs. For a JSON key of a secret use `<secret-arn>:<json-key>::`.

### Costs

- Fargate: billed per vCPU / memory-second while the job runs. Fargate Spot is cheaper and can be interrupted.
- EC2: billed while instances run. Keep `ec2_config.min_vcpus = 0` so the environment scales to zero.
- Schedules, rules, logs: low cost. Keep `log_retention_days` small in dev.
- Run `make infracost-breakdown` from the repository root before large changes.

## CI/CD: deploy pipeline for job definitions

This layer does **not** create the pipeline IAM role. The flow below is the agreed approach. Build and push the
image to ECR with the image pipeline (see the "build and push to ECR" task), then:

1. Keep the job definition template in the **application repository**, e.g. `batch/job-definition.json`.
   Generate the first version from the job definition this layer registered:
   ```bash
   aws batch describe-job-definitions --job-definition-name bb-devstg-batch-demoapp-<key> --status ACTIVE \
     --query 'sort_by(jobDefinitions,&revision)[-1].{jobDefinitionName:jobDefinitionName,type:type,platformCapabilities:platformCapabilities,containerProperties:containerProperties,retryStrategy:retryStrategy,timeout:timeout,propagateTags:propagateTags}' \
     > batch/job-definition.json
   ```
2. The pipeline replaces the image and registers a new revision. Schedules use the job definition **name**,
   so the next run uses the new revision automatically.
3. Authenticate with **GitHub OIDC** (no static AWS keys). The `apps-devstg` account already has the GitHub OIDC
   provider (`apps-devstg/global/github-oidc-tofu-plan`, output `github_oidc_provider_arn`). The pipeline role
   needs:
   - `batch:RegisterJobDefinition`, `batch:DescribeJobDefinitions`
   - `iam:PassRole` on the `execution_role_arn` and `job_role_arn` outputs
4. Send the result to Slack.

Example GitHub Actions job:

```yaml
jobs:
  deploy-batch-job-definition:
    runs-on: ubuntu-latest
    permissions:
      id-token: write   # GitHub OIDC
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_BATCH_DEPLOY_ROLE_ARN }}
          aws-region: us-east-1
      - name: Register a new job definition revision
        env:
          IMAGE: ${{ vars.ECR_REPOSITORY_URI }}:${{ github.sha }}
        run: |
          jq --arg image "$IMAGE" '.containerProperties.image = $image' batch/job-definition.json > /tmp/jobdef.json
          aws batch register-job-definition --cli-input-json file:///tmp/jobdef.json \
            --query '[jobDefinitionName,revision]' --output text
      - name: Notify Slack
        if: always()
        uses: slackapi/slack-github-action@v2
        with:
          webhook: ${{ secrets.SLACK_WEBHOOK_URL }}
          webhook-type: incoming-webhook
          payload: |
            text: "Batch job definition deploy for ${{ github.repository }}@${{ github.sha }}: ${{ job.status }}"
```

> **Revisions owned by OpenTofu and by the pipeline.** OpenTofu tracks only the revision it registered, so it
> does not see pipeline revisions as drift. However, when a later `tofu apply` changes a job definition, OpenTofu
> registers a new revision with the `image` in its own variables, and that revision becomes the latest. Before
> such an apply, set `image` to the tag the pipeline last deployed.

## Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| Job stuck in `RUNNABLE` | No capacity: `max_vcpus` too small for the job, invalid Fargate vCPU/memory combination, GPU quota is 0, or instances cannot reach ECS (no egress). Check the compute environment status and `job_queue.job_state_time_limit_actions`. |
| `CannotPullContainerError` | No egress to ECR / public ECR (see [Prerequisites](#prerequisites)), image tag missing, or the ECR repository policy does not allow this account. |
| `ResourceInitializationError: unable to retrieve secret` | Wrong secret ARN, no egress to Secrets Manager / SSM, or a KMS key policy that does not allow the account. |
| Compute environment `INVALID` | Read `statusReason` in `aws batch describe-compute-environments`. With a custom EBS KMS key, see prerequisite 5. |
| No Slack message on failure | `notifications` layer not applied (no `workload-monitoring` topic yet), or the job is in another queue. Check the rule's `FailedInvocations` metric. |
| Schedule does not run | Schedule `enabled = false`, wrong time zone, or the scheduler role lacks `batch:SubmitJob` for that job definition (it is granted only for definitions used in `schedules`). |

Connect to an EC2 container instance (when `ec2_config.enable_ssm = true` and SSM is reachable):
`aws ssm start-session --target <instance-id>`.

## Delivery tasks covered

| Task (binbash tasks template, AWS BATCH) | Where |
| --- | --- |
| AWS Batch on Fargate (compute environment, job queue, job definitions, IAM) | `compute_type = "FARGATE"`, `batch.tf`, `iam.tf`, `logs.tf` |
| AWS Batch on managed EC2 with GPU | `compute_type = "EC2"/"SPOT"`, `ec2_config.gpu_enabled`, `launch_template.tf` |
| Scheduler for AWS Batch jobs | `schedules`, `eventbridge.tf` |
| Deploy pipeline for AWS Batch job definitions | [CI/CD section](#cicd-deploy-pipeline-for-job-definitions) (docs only) |
| Failure notifications for AWS Batch jobs | `failure_notifications`, `eventbridge.tf`, `notifications` layer |
| Knowledge transfer | This README: [Day-2 operations](#day-2-operations), [Verify](#verify), [Troubleshooting](#troubleshooting) |

## References

- [AWS Batch getting started (Hello World)](https://docs.aws.amazon.com/batch/latest/userguide/Batch_GetStarted.html)
- [AWS Batch on Fargate](https://docs.aws.amazon.com/batch/latest/userguide/fargate.html)
- [Compute environments](https://docs.aws.amazon.com/batch/latest/userguide/compute_environments.html) · [Job queues](https://docs.aws.amazon.com/batch/latest/userguide/job_queues.html) · [Job definitions](https://docs.aws.amazon.com/batch/latest/userguide/job_definitions.html)
- [GPU jobs](https://docs.aws.amazon.com/batch/latest/userguide/gpu-jobs.html) · [Allocation strategies](https://docs.aws.amazon.com/batch/latest/userguide/allocation-strategies.html) · [Launch templates](https://docs.aws.amazon.com/batch/latest/userguide/launch-templates.html)
- [Execution role](https://docs.aws.amazon.com/batch/latest/userguide/execution-IAM-role.html) · [Instance role](https://docs.aws.amazon.com/batch/latest/userguide/instance_IAM_role.html) · [Sensitive data](https://docs.aws.amazon.com/batch/latest/userguide/specifying-sensitive-data.html)
- [Scheduled Batch jobs with EventBridge Scheduler](https://docs.aws.amazon.com/batch/latest/userguide/scheduled-batch-job.html) · [Batch events](https://docs.aws.amazon.com/batch/latest/userguide/batch_cwe_events.html)
