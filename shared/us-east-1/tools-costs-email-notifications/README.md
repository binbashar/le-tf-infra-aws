# AWS Cost Summary Report Script with Terraform

The AWS Cost Summary Report Script with Terraform is a comprehensive solution for generating monthly cost reports for multiple AWS accounts. It combines a Python script and Terraform configuration to automate the setup and execution of the cost reporting process. This README provides an overview of the Terraform code used in the solution.

## Terraform Resources

### `aws_iam_role` - `monthly_services_usage_lambda_role`

- **Name**: `monthly-services-usage-lambdarole`
- **Description**: IAM role for the Lambda function responsible for generating cost reports.
- **Assume Role Policy**: Allows Lambda to assume this role.

### `aws_iam_policy` - `monthly_services_usage_lambda_role_policy`

- **Name**: `MonthlyServicesUsageLambdaRolePolicy`
- **Description**: IAM policy attached to the Lambda role.
- **Permissions**: Allows actions related to CloudWatch Logs, SES, and assuming specified roles in other AWS accounts.

### `aws_iam_role_policy_attachment` - `attach_policy_to_role`

- **Description**: Attaches the `monthly_services_usage_lambda_role_policy` to the `monthly_services_usage_lambda_role`.

### `data "archive_file"` - `lambda`

- **Type**: ZIP
- **Description**: Archives the Python script `script.py` into a Lambda deployment package `lambda_function_payload.zip`.

### `aws_lambda_function` - `monthly_services_usage`

- **Description**: Deploys the Lambda function responsible for generating the cost report.
- **Runtime**: Python 3.9
- **Timeout**: 300 seconds
- **Environment Variables**: Sets environment variables including AWS accounts information, sender email, and recipient emails.
- **Trigger**: Scheduled execution using CloudWatch Events.

### `aws_cloudwatch_event_rule` - `monthly_services_usage_scheduler`

- **Description**: Defines a CloudWatch Events rule to trigger the Lambda function on a scheduled basis.
- **Schedule Expression**: Customizable based on your desired schedule.

### `aws_cloudwatch_event_target` - `lambda_target`

- **Description**: Specifies the Lambda function as the target for the CloudWatch Events rule.

### `aws_lambda_permission` - `lambda_invoke_permission`

- **Description**: Grants permission for CloudWatch Events to invoke the Lambda function.

### `aws_ses_email_identity` - `monthly_services_usage_sender`

- **Description**: Configures SES email identity for the sender's email address.

## Prerequisites

Before deploying this Terraform configuration, make sure you have the following:

1. AWS CLI and Terraform installed and configured with the necessary permissions.
2. The `script.py` Python script for generating cost reports.

## Usage

1. Clone or download this repository to your local environment.

2. Modify the Terraform variables and configurations as needed to match your AWS environment, including the schedule expression for report generation.

3. Run `leverage terraform init` and `leverage terraform apply` to provision the resources.

4. Deploy the Python script `script.py` to the Lambda function.

5. The Lambda function will be triggered based on the schedule expression to generate cost reports and send them via SES.

IMPORTANT: given the multi-account nature of this solution, you will need to have in mind that the execution Role need permissions to assume the `LambdaCostsExplorerAccess` role on all the required accounts. We have already added the permissions to assume the roles like this:
```
"arn:aws:iam::${var.accounts.shared.id}:role/LambdaCostsExplorerAccess"
"arn:aws:iam::${var.accounts.apps-devstg.id}:role/LambdaCostsExplorerAccess"
"arn:aws:iam::${var.accounts.apps-prd.id}:role/LambdaCostsExplorerAccess"
"arn:aws:iam::${var.accounts.management.id}:role/LambdaCostsExplorerAccess"
"arn:aws:iam::${var.accounts.security.id}:role/LambdaCostsExplorerAccess"
```
If you need to add more accounts, you will need to add the corresponding ARN to the `aws_iam_policy` resource `monthly_services_usage_lambda_role_policy` in the `assume_role` section.

Take into account that you may need to have the assumable role `LambdaCostsExplorerAccess` created on all accounts you want to generate the cost reports for, adding as a trusted entity the account where you are deploying the solution, in this case the `shared` account.

# Analysis of the Python code

The AWS Cost Summary Report Script is a Python script designed to generate monthly cost reports for multiple AWS accounts. It retrieves cost and usage data from AWS Cost Explorer, calculates cost variations, and generates an HTML report that is emailed to specified recipients using Amazon SES.

## Features

- **Multi-Account Support**: The script supports processing cost data for multiple AWS accounts, allowing you to consolidate cost information from various accounts into a single report.

- **Cost Calculation**: It retrieves cost data from AWS Cost Explorer, including unblended costs, and groups the costs by service to provide a detailed breakdown.

- **Cost Variation**: The script calculates variations in costs for each service compared to the previous month. It highlights cost variations in the report.

- **Custom Tag Support**: The script can filter costs based on custom tags. For example, it can calculate costs associated with the 'perception-ml' tag and display them separately.

- **Email Notifications**: The generated report is sent via email using Amazon SES to specified recipients.

## Prerequisites

Before using this script, you need to set up the following:

1. **AWS IAM Roles**: Create IAM roles with appropriate permissions in each AWS account that allows access to AWS Cost Explorer. Update the `create_ce_client` function with the correct role ARN if needed.

2. **Environment Variables**: Set the necessary environment variables:

   - `ACCOUNTS`: A JSON string containing information about the AWS accounts to process.
   - `SENDER`: The sender's email address for SES.
   - `RECIPIENT`: A comma-separated list of recipient email addresses for the report.

3. **Amazon SES Configuration**: Ensure that your AWS environment has Amazon SES configured with the appropriate permissions to send emails.

| :point_up: Note   |
|:---------------|
| If you have SES in place but you've created a new identity (email sender and/or receiver/s) VERIFY it in the [AWS SES Console](https://us-east-1.console.aws.amazon.com/ses/home?region=us-east-1#/identities)! (this is for `us-east-1`, change the region as per your own settings) |

## How it Works

1. The script calculates the start and end dates for the past month and the month before that.

2. It fetches cost data for each AWS account and groups it by service.

3. It calculates the cost variation for each service compared to the previous month and highlights variations.

4. The script generates an HTML report with detailed cost breakdown and sends it via email to the specified recipients.
