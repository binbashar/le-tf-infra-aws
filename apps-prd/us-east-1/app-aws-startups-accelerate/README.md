# app-aws-startups-accelerate

Static frontend hosting following the Leverage **"app frontend on AWS"**
pattern: a fully static app served from a private S3 origin behind CloudFront,
deployed by the app repository's CI through a least-privilege GitHub OIDC role
— no long-lived AWS keys, near-zero monthly cost.

## What this layer provisions

| Concern | Resources |
| --- | --- |
| **Serving** | CloudFront distribution (`PriceClass_100`, TLS 1.2+, compression) with a private S3 origin (OAC, SSE, SSL-enforced, public access blocked) and a viewer-request CloudFront Function rewriting directory-style URLs to `index.html`; 403/404 mapped to the app's `404.html` |
| **DNS / TLS** | A/AAAA alias records in the shared account public zone (cross-account `aws.shared-route53` provider); ACM certificate consumed from the `security-certs` layer via remote state |
| **Deploy identity** | GitHub OIDC identity provider (`var.create_github_oidc_provider`) + deploy role limited to `s3 sync` and CloudFront invalidation, trust scoped via the `sub` claim to `var.github_repository` @ `var.github_branch` |
| **Operations** | CloudFront access logs (dedicated bucket, `var.log_expiration_days` expiry) and `5xxErrorRate`/`TotalErrorRate` CloudWatch alarms wired to the `notifications` layer SNS topic |
| **Phase 2 (disabled)** | `backend-stub.tf` documents future backend IAM hooks; intentionally not provisioned |

## Deployment

1. Apply `apps-prd/us-east-1/security-certs` first — this layer consumes its
   ACM certificate ARN via `terraform_remote_state` and cannot plan until the
   certificate exists.
2. From this directory: `leverage tofu init && leverage tofu plan && leverage tofu apply`
   (requires valid `bb-apps-prd-devops` and `bb-shared-devops` credentials).

Outputs consumed by the app repository CI: `deploy_role_arn`, `s3_bucket`,
`cf_distribution_id` (`leverage tofu output`).

## App-specific documentation

The application details (architecture diagram, CI deploy workflow handoff,
build requirements, smoke tests) live in the app repository — private:
[`binbashar/bb-ai-sales-tools` → `apps/aws-startups-accelerate/docs/infra`](https://github.com/binbashar/bb-ai-sales-tools/tree/main/apps/aws-startups-accelerate/docs/infra)
