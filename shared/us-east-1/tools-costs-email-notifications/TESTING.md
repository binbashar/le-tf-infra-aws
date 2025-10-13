# Testing MonthlyServicesUsage Lambda Function

This document provides guidance on testing the MonthlyServicesUsage Lambda function.

## Prerequisites

- Access to the AWS account where the Lambda function is deployed
- IAM permissions to invoke Lambda functions and view CloudWatch logs

## Testing Methods

### 1. AWS Lambda Console Testing

**⚠️ WARNING:** Testing the function will send emails to ALL configured recipients. Consider temporarily modifying the `RECIPIENT` environment variable to your own email address before testing.

1. Navigate to the AWS Lambda console
2. Select the `MonthlyServicesUsage` function
3. Click the **Test** tab
4. Create a new test event with the following JSON:

```json
{
  "test": "manual-invocation"
}
```

5. Click **Test** to invoke the function
6. Review the execution results and logs


### 2. Testing with Leverage CLI

**⚠️ WARNING:** Testing the function will send emails to ALL configured recipients. Consider temporarily modifying the `RECIPIENT` environment variable to your own email address before testing.

If using Leverage CLI:

```bash
# Navigate to the layer directory
cd <PROJECT_PATH>/shared/us-east-1/tools-costs-email-notifications

# Authenticate
leverage aws sso login

# Deploy/update the function
leverage tf refresh-credentials

# Test using AWS CLI through Leverage
leverage aws --profile bb-shared-devops lambda invoke \
    --function-name MonthlyServicesUsage \
    --payload \'{\"test\": \"leverage-invocation\" }\' \
    --cli-binary-format raw-in-base64-out \
    --region us-east-1 response.json
```

## Environment Variables Required

Ensure the following environment variables are configured:

- `ACCOUNTS`: JSON-encoded map of account names to account IDs
  ```json
  {
    "apps-devstg": {"id": "123456789012"},
    "apps-prd": {"id": "123456789013"}
  }
  ```
- `SENDER`: Email address for the sender (must be verified in SES)
- `RECIPIENT`: Comma-separated list of recipient email addresses
- `TAGS_JSON`: JSON-encoded map of cost allocation tags (max 3)
- `EXCLUDE_CREDITS`: Boolean to exclude AWS credits from the report
- `FORCE_DATE`: Optional date to override the report date (format: YYYY-MM-DD)
- `REGION`: AWS region (default: us-east-1)

## Testing Error Handling

### Test 1: Missing/Invalid Role

To test error handling when role assumption fails:

1. Temporarily modify the account configuration to include a non-existent account ID
2. Invoke the function
3. Verify that:
   - The function doesn't crash
   - Error is logged in CloudWatch
   - Email is sent with a warning notice for failed accounts
   - Other accounts are processed successfully

### Test 2: Force Function Crash for Slack Notification

To test CloudWatch alarms and Slack notifications when the function crashes:

**Method 1: Temporarily break the Lambda code**

1. Navigate to the Lambda function in AWS Console
2. Add a syntax error or force an exception early in the handler:
   ```python
   def lambda_handler(event, context):
       raise Exception("Testing Slack notification on Lambda crash")
       # rest of the code...
   ```
3. Save the changes
4. Invoke the function using any of the testing methods above
5. Verify that:
   - Lambda execution fails with an error
   - CloudWatch alarm `MonthlyServicesUsageLambdaErrors` is triggered
   - Slack notification is received in the configured channel (le-tools-monitoring-sec)
   - Error details appear in CloudWatch logs

**Method 2: Remove required IAM permissions**

1. Temporarily remove SES permissions from the Lambda IAM role
2. Invoke the function
3. The function will crash when attempting to send emails
4. Verify Slack notification is received

**Method 3: Use invalid environment variables**

1. Set `ACCOUNTS` environment variable to invalid JSON:
   ```
   ACCOUNTS="{invalid json"
   ```
2. Invoke the function
3. Function will crash during initialization
4. Verify Slack notification is received

**Verification Steps:**

After triggering a crash, check:
- [ ] CloudWatch alarm state changes to `ALARM`
- [ ] Slack message received in the monitoring channel
- [ ] Slack message contains relevant error information
- [ ] CloudWatch logs show the error details
- [ ] SNS topic successfully publishes to Slack Lambda

**Important:** Remember to revert any changes made for testing purposes.

## Monitoring and Logs

### CloudWatch Logs

View logs in real-time:
```bash
aws logs tail /aws/lambda/MonthlyServicesUsage --follow --region us-east-1
```

Filter for errors:
```bash
aws logs filter-log-events \
    --log-group-name /aws/lambda/MonthlyServicesUsage \
    --filter-pattern "[ERROR]" \
    --region us-east-1
```

### CloudWatch Alarms

The infrastructure includes CloudWatch alarms that trigger on:
- Lambda function errors (any error)
- Complete function failures (returns 500 status)

Monitor alarms:
```bash
aws cloudwatch describe-alarms \
    --alarm-names MonthlyServicesUsageLambdaErrors \
    --region us-east-1
```

## Validation Checklist

After testing, verify:

- [ ] Function executes without crashing
- [ ] Email is successfully sent to all recipients
- [ ] Cost data is accurate for all accounts
- [ ] Failed accounts are logged and included in the email warning
- [ ] CloudWatch logs contain detailed execution information
- [ ] No sensitive data is logged
- [ ] CloudWatch alarms are properly configured
- [ ] IAM permissions follow least privilege principle
- [ ] SES sender and recipients are verified

## Troubleshooting

### Common Issues

1. **Role assumption failures**
   - Verify the `LambdaCostsExplorerAccess` role exists in target accounts
   - Check trust relationship allows the Lambda role to assume it
   - Verify IAM permissions in iam.tf

2. **SES sending failures**
   - Ensure sender email is verified in SES
   - Verify recipient emails (if in sandbox mode)
   - Check IAM permissions for SES actions


