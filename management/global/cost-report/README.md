# Cost Report Module - Quick Reference

This module deploys a Lambda function to fetch AWS cost data and post a daily report to Slack.

## Key Considerations

- **Lambda Source**: Uses `terraform-aws-lambda` (binbashar) module, with code in the `src/` directory.
- **Python Packaging**: The function has no third-party dependencies (standard library plus the runtime's bundled `boto3`), so there is no `requirements.txt` and the package is a plain zip of `src/` — applying needs neither Docker nor pip (`build_in_docker = false`). Adding a dependency would require building it in Docker again.
- **Slack Integration**: Requires a valid Slack webhook URL in the environment variables.
- **Permissions**: Lambda is granted only the minimum required permissions (`ce:GetCostAndUsage`, `iam:ListAccountAliases`).
- **Scheduling**: Triggered daily at a configurable time via CloudWatch EventBridge rule (`var.report_run_schedule`).
- **Environment Variables**: Control report length, grouping, and Slack destination. Adjust as needed.
- **Logs**: CloudWatch logs are retained for 7 days.
- **Report window**: the 7 UTC days before the run. Yesterday is always flagged *partial* (dated, with a `*` on the `Yday*` column), because Cost Explorer has usually not finished billing it when the report runs at 12:00 UTC.

## Testing

`src/` is the whole Lambda package, so tests live in `tests/` and are never deployed. From the repository root:

- `make cost-report-test` — offline tests against the synthetic Cost Explorer responses in `tests/fixtures/` (no AWS calls; the suite fails any test that tries).
- `make cost-report-preview` — builds the report from live Cost Explorer data with the management profile and prints it instead of posting to Slack. Each run is one billed request ($0.01).

### Access to Slack Webhook Secret

- **Secret Storage**: The Slack webhook URL is stored securely in AWS Secrets Manager, not directly in Lambda environment variables. The secret is encrypted using a customer-managed KMS key (CMK).
- **IAM Permissions**: The Lambda function is granted permission to call `secretsmanager:GetSecretValue` on the specific secret ARN, and `kms:Decrypt` on the relevant KMS key, via inline policies in `main.tf`.
- **Runtime Retrieval**: At runtime, the Lambda reads the secret ARN from the `SLACK_WEBHOOK_SECRET_ID` environment variable and fetches the actual webhook URL using the AWS SDK (`boto3`).
- **Usage**: This approach ensures the Slack webhook URL is never exposed in plaintext in the Lambda configuration or logs, and can be rotated easily in Secrets Manager without redeploying the function. The use of a KMS CMK ensures that only authorized resources (like this Lambda) can decrypt and access the secret value.

> For advanced configuration or troubleshooting, review the comments in `main.tf`.
