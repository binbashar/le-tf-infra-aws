data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/kyb-bda-processor"
  output_path = "${path.module}/kyb-bda-processor.zip"
}

resource "aws_lambda_function" "kyb_bda_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = local.lambda_function_name
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      BDA_PROJECT_ARN = awscc_bedrock_data_automation_project.kyb_project.project_arn
      BDA_PROFILE_ARN = local.bda_profile_arn
      OUTPUT_BUCKET   = aws_s3_bucket.kyb_output.bucket
      LOG_LEVEL       = "INFO"
    }
  }

  tags = merge(local.tags, {
    Name = local.lambda_function_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy,
    aws_cloudwatch_log_group.lambda_logs
  ]
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.kyb_bda_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_trigger.arn
}