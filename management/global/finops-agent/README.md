# FinOps Agent (management account)

Provisions the IaC-able foundation for the [AWS FinOps Agent](https://aws.amazon.com/finops-agent/) (preview) in the management (payer) account, us-east-1.

## What this layer manages vs. what is manual

The FinOps Agent **agentspace** is created only through a preview API (`finops-agent:CreateAgentSpace`). There is **no CloudFormation resource type** for it, and because CDK and the Terraform `awscc` provider are both generated from the CloudFormation registry, **neither CDK nor awscc can create it either**. The plain `hashicorp/aws` provider has no `aws_finops*` resource. So CDK offers no advantage over OpenTofu here.

This layer therefore manages everything that *is* IaC-able, and the agentspace is the single documented manual step.

```
┌──────────────────── management account · us-east-1 ────────────────────┐
│   OpenTofu (this layer)                    Manual (one-time, preview)   │
│   ─────────────────────                    ─────────────────────────    │
│   aws_iam_role.agent      ──────┐          Console wizard →             │
│     + agent policy              ├────────► CreateAgentSpace             │
│   aws_iam_role.operator   ──────┤          Step 2: use existing role    │
│     + operator policy           │            → agent_role_arn           │
│   (trust: finops-agent.         └────────► Step 3: use existing role    │
│    amazonaws.com)                            → operator_role_arn        │
│   aws_ce_anomaly_monitor            ← anomaly-investigation feature     │
│   aws_computeoptimizer_enrollment_status  ← rightsizing recs (mgmt)     │
└─────────────────────────────────────────────────────────────────────────┘
```

## Deploy

```bash
cd management/global/finops-agent
leverage tofu init
leverage tofu plan
leverage tofu apply   # human step, after PR approval
```

## Create the agentspace (one-time, manual)

1. Open the AWS FinOps Agent console in the management account (us-east-1).
2. **Create agent** → name it (e.g. `binbash-finops-agent`).
3. **Step 2 (AWS resources access):** choose **Use an existing role** → paste the `agent_role_arn` output.
4. **Step 3 (web app access):** choose **Use an existing role** → paste the `operator_role_arn` output.
5. **Step 4 (integrations):** optional Jira/Slack — not managed here.
6. **Create.** Confirm both roles appear under **Permissions** on the agent detail page.

Get the ARNs:

```bash
leverage tofu output agent_role_arn
leverage tofu output operator_role_arn
```

## Permission policies

The agent and operator policies are kept **inline** (customer-managed `aws_iam_policy`) rather than attaching AWS's managed `FinOpsAgentAgentPolicy` / `FinOpsAgentOperatorPolicy`, because the service is in preview (managed-policy ARNs may change or not be attachable yet) and inline keeps the exact permission set git-visible. They mirror the [AWS IAM setup guide](https://docs.aws.amazon.com/finops-agent/latest/userguide/setting-up.html) verbatim. To switch to the managed policies later, replace each `aws_iam_policy` + attachment pair with an `aws_iam_role_policy_attachment` referencing the managed ARN.

## Why no `aws-apn-id` tag

Per the repo `CLAUDE.md`, the `aws-apn-id` PRM tag is reserved for specific Bedrock AWS Marketplace layers and must not be added elsewhere without Partner Development Manager approval. This layer intentionally omits it.

## Migration note

When AWS ships a CloudFormation resource type for the agentspace (which would also unlock `awscc` and CDK), replace the manual `CreateAgentSpace` step with the native resource, wire it to the existing role ARNs, and `import` the already-created agentspace into state. Until then, roles + prerequisites are fully managed here and only the agentspace is manual.
