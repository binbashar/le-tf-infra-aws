data "archive_file" "lambda" {
  type        = "zip"
  source_file = "src/script.py"
  output_path = "src/lambda_function_payload.zip"
}

resource "aws_lambda_function" "monthly_services_usage" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "src/lambda_function_payload.zip"
  function_name = "MonthlyServicesUsage"
  role          = aws_iam_role.monthly_services_usage_lambda_role.arn
  handler       = "script.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.9"
  timeout = 300

  environment {
    variables = {
      ACCOUNTS        = jsonencode(var.accounts)
      SENDER          = var.sender_email
      RECIPIENT       = join(",", var.recipient_emails)
      TAGS_JSON       = jsonencode(var.cost_allocation_tags)
      EXCLUDE_CREDITS = var.exclude_aws_credits
    }
  }

  lifecycle {
    ignore_changes = [
      memory_size,
      timeout
    ]
  }

}