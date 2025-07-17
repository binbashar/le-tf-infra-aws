# Cost Report Module - Quick Reference

This module deploys a Lambda function to fetch AWS cost data and post a daily report to Slack.

## Key Considerations

- **Lambda Source**: Uses `terraform-aws-lambda` (binbashar) module, with code in the `src/` directory.
- **Python Packaging**: Lambda dependencies must be built in Docker (`build_in_docker = true`) due to packaging issues with PIP in the default environment.
- **Slack Integration**: Requires a valid Slack webhook URL in the environment variables.
- **Permissions**: Lambda is granted only the minimum required permissions (`ce:GetCostAndUsage`, `iam:ListAccountAliases`).
- **Scheduling**: Triggered daily at a configurable time via CloudWatch EventBridge rule (`var.report_run_schedule`).
- **Environment Variables**: Control report length, grouping, and Slack destination. Adjust as needed.
- **Logs**: CloudWatch logs are retained for 7 days.

### Access to Slack Webhook Secret

- **Secret Storage**: The Slack webhook URL is stored securely in AWS Secrets Manager, not directly in Lambda environment variables. The secret is encrypted using a customer-managed KMS key (CMK).
- **IAM Permissions**: The Lambda function is granted permission to call `secretsmanager:GetSecretValue` on the specific secret ARN, and `kms:Decrypt` on the relevant KMS key, via inline policies in `main.tf`.
- **Runtime Retrieval**: At runtime, the Lambda reads the secret ARN from the `SLACK_WEBHOOK_SECRET_ID` environment variable and fetches the actual webhook URL using the AWS SDK (`boto3`).
- **Usage**: This approach ensures the Slack webhook URL is never exposed in plaintext in the Lambda configuration or logs, and can be rotated easily in Secrets Manager without redeploying the function. The use of a KMS CMK ensures that only authorized resources (like this Lambda) can decrypt and access the secret value.

> For advanced configuration or troubleshooting, review the comments in `main.tf`.
