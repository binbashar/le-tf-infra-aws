data "archive_file" "lambda" {
  type        = "zip"
  source_file = "src/script.py"
  output_path = "src/lambda_function_payload.zip"
}

resource "aws_lambda_function" "monthly_services_usage" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "src/lambda_function_payload.zip"
  function_name = local.lambda_function_name
  role          = aws_iam_role.monthly_services_usage_lambda_role.arn
  handler       = "script.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.9"
  timeout = 300

  environment {
    variables = {
      # ACCOUNTS is only used as fallback when AUTO_DISCOVER_ACCOUNTS=false or if auto-discovery fails
      ACCOUNTS               = jsonencode(var.accounts)
      AUTO_DISCOVER_ACCOUNTS = tostring(var.auto_discover_accounts)
      EXCLUDED_ACCOUNT_IDS   = join(",", var.excluded_account_ids)
      SENDER                 = var.sender_email
      RECIPIENT              = join(",", var.recipient_emails)
      TAGS_JSON              = jsonencode(var.cost_allocation_tags)
      EXCLUDE_CREDITS        = tostring(var.exclude_aws_credits)
      FORCE_DATE             = var.force_start_date
      REGION                 = var.region
    }
  }

  lifecycle {
    ignore_changes = [
      memory_size,
      timeout
    ]
  }

}