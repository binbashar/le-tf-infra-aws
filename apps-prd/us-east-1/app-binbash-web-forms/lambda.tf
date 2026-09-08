#
# The deployment package. archive_file zips the source directory as-is — there is
# no build step and no dependency install, which is why the handler uses nothing
# beyond the stdlib and boto3 (bundled in the Python runtime).
#
data "archive_file" "careers_application" {
  type        = "zip"
  source_dir  = "${path.module}/src/careers-application"
  output_path = "${path.module}/careers-application.zip"
  excludes    = ["test_lambda_function.py", "__pycache__", ".pytest_cache"]
}

#
# Created explicitly rather than left to Lambda's implicit creation, so retention
# is set and the IAM policy above can name it.
#
resource "aws_cloudwatch_log_group" "careers_application" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

resource "aws_lambda_function" "careers_application" {
  function_name    = local.function_name
  role             = aws_iam_role.careers_application.arn
  filename         = data.archive_file.careers_application.output_path
  source_code_hash = data.archive_file.careers_application.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 10
  memory_size      = 128

  # A form on a marketing site does not need unbounded concurrency, and capping
  # it means a burst that gets past the stage throttle still cannot run up an
  # SES bill or exhaust the account's concurrency pool.
  reserved_concurrent_executions = 5

  environment {
    variables = {
      SES_FROM_EMAIL    = var.ses_from_email
      CAREERS_RECIPIENT = var.careers_recipient
      LOG_LEVEL         = "INFO"
    }
  }

  tags = merge(local.tags, { Name = local.function_name })

  depends_on = [
    aws_iam_role_policy.careers_application,
    aws_cloudwatch_log_group.careers_application,
  ]
}
