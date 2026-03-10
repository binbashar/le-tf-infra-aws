resource "aws_cloudwatch_event_rule" "input_bucket_trigger" {
  name        = local.input_rule_name
  description = "Trigger BDA processing when PDFs are uploaded to input bucket"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.input.bucket]
      }
      object = {
        key = [{
          "suffix" = ".pdf"
        }]
      }
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "bda_invoker_target" {
  rule      = aws_cloudwatch_event_rule.input_bucket_trigger.name
  target_id = "BDAInvokerTarget"
  arn       = aws_lambda_function.bda_invoker.arn

  retry_policy {
    maximum_retry_attempts       = 2
    maximum_event_age_in_seconds = 3600
  }
}
