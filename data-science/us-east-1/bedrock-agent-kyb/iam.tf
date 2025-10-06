data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "bda_invoker_policy" {
  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.bda_invoker_name}:*"]
  }

  statement {
    sid       = "S3ObjectAccess"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.input.arn}/*"]
  }

  statement {
    sid     = "S3BucketAccess"
    effect  = "Allow"
    actions = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [
      aws_s3_bucket.input.arn,
      aws_s3_bucket.processing.arn
    ]
  }

  statement {
    sid    = "BDAAccess"
    effect = "Allow"
    actions = [
      "bedrock:InvokeDataAutomationAsync",
      "bedrock:GetDataAutomationStatus"
    ]
    resources = [
      "arn:aws:bedrock:us-east-1:*:data-automation-project/*",
      "arn:aws:bedrock:us-east-1:*:data-automation-profile/*",
      "arn:aws:bedrock:us-east-2:*:data-automation-profile/*",
      "arn:aws:bedrock:us-west-1:*:data-automation-profile/*",
      "arn:aws:bedrock:us-west-2:*:data-automation-profile/*"
    ]
  }

  statement {
    sid       = "S3ProcessingBucketAccess"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.processing.arn}/*"]
  }
}

data "aws_iam_policy_document" "agent_invoker_policy" {
  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.agent_invoker_name}:*"]
  }

  statement {
    sid       = "BedrockAgentAccess"
    effect    = "Allow"
    actions   = ["bedrock:InvokeAgent"]
    resources = ["arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:agent/*"]
  }

  statement {
    sid    = "S3ProcessingBucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      aws_s3_bucket.processing.arn,
      "${aws_s3_bucket.processing.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "get_documents_policy" {
  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.get_documents_name}:*"]
  }

  statement {
    sid    = "S3ProcessingBucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      aws_s3_bucket.processing.arn,
      "${aws_s3_bucket.processing.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "save_document_policy" {
  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.save_document_name}:*"]
  }

  statement {
    sid       = "S3OutputBucketAccess"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.output.arn}/*"]
  }
}

resource "aws_iam_role" "bda_invoker_role" {
  name               = "${local.bda_invoker_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.tags
}

resource "aws_iam_policy" "bda_invoker_policy" {
  name   = "${local.bda_invoker_name}-policy"
  policy = data.aws_iam_policy_document.bda_invoker_policy.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "bda_invoker_policy" {
  role       = aws_iam_role.bda_invoker_role.name
  policy_arn = aws_iam_policy.bda_invoker_policy.arn
}

resource "aws_iam_role" "agent_invoker_role" {
  name               = "${local.agent_invoker_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.tags
}

resource "aws_iam_policy" "agent_invoker_policy" {
  name   = "${local.agent_invoker_name}-policy"
  policy = data.aws_iam_policy_document.agent_invoker_policy.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "agent_invoker_policy" {
  role       = aws_iam_role.agent_invoker_role.name
  policy_arn = aws_iam_policy.agent_invoker_policy.arn
}

resource "aws_iam_role" "get_documents_role" {
  name               = "${local.get_documents_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.tags
}

resource "aws_iam_policy" "get_documents_policy" {
  name   = "${local.get_documents_name}-policy"
  policy = data.aws_iam_policy_document.get_documents_policy.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "get_documents_policy" {
  role       = aws_iam_role.get_documents_role.name
  policy_arn = aws_iam_policy.get_documents_policy.arn
}

resource "aws_iam_role" "save_document_role" {
  name               = "${local.save_document_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.tags
}

resource "aws_iam_policy" "save_document_policy" {
  name   = "${local.save_document_name}-policy"
  policy = data.aws_iam_policy_document.save_document_policy.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "save_document_policy" {
  role       = aws_iam_role.save_document_role.name
  policy_arn = aws_iam_policy.save_document_policy.arn
}

#======================================
# Lambda Permissions
#======================================

resource "aws_lambda_permission" "allow_apigw_invoke_agent" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.agent_invoker.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.apigw_kyb_agent.aws_api_gateway_stage_execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_eventbridge_bda_invoker" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bda_invoker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.input_bucket_trigger.arn
}

resource "aws_lambda_permission" "allow_bedrock_get_documents" {
  statement_id  = "AllowExecutionFromBedrock"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_documents.function_name
  principal     = "bedrock.amazonaws.com"
  source_arn    = "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:agent/*"
}

resource "aws_lambda_permission" "allow_bedrock_save_document" {
  statement_id  = "AllowExecutionFromBedrock"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.save_document.function_name
  principal     = "bedrock.amazonaws.com"
  source_arn    = "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:agent/*"
}

#======================================
# API Gateway IAM Policy
#======================================

resource "aws_iam_policy" "api_invoke_policy" {
  name        = "${var.project}-${var.environment}-kyb-agent-api-invoke"
  description = "Allows invoking the KYB Agent API Gateway endpoint"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "execute-api:Invoke"
      Resource = "${module.apigw_kyb_agent.aws_api_gateway_stage_execution_arn}/*"
    }]
  })

  tags = local.tags
}
