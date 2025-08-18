resource "aws_cloudwatch_event_rule" "s3_trigger" {
  name        = local.eventbridge_rule_name
  description = "Trigger KYB BDA processing when objects are created in the input bucket"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.kyb_input.bucket]
      }
      object = {
        key = [{
          "exists" = true
        }]
      }
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.s3_trigger.name
  target_id = "KYBBDAProcessorTarget"
  arn       = aws_lambda_function.kyb_bda_processor.arn

  retry_policy {
    maximum_retry_attempts       = 3
    maximum_event_age_in_seconds = 3600
  }

  dead_letter_config {
    arn = aws_sqs_queue.dlq.arn
  }
}

resource "aws_sqs_queue" "dlq" {
  name = "${local.lambda_function_name}-dlq"

  message_retention_seconds = 1209600 # 14 days
  visibility_timeout_seconds = 60

  tags = merge(local.tags, {
    Purpose = "dead-letter-queue"
  })
}

resource "aws_sqs_queue_policy" "dlq_policy" {
  queue_url = aws_sqs_queue.dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgeToSendMessage"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.dlq.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Using data.aws_caller_identity.current from config.tf