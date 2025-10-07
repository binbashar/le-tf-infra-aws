#================================
# Lambda Execution Roles
#================================

resource "aws_iam_role" "lambda_execution_role" {
  name = "${local.name_prefix}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "${local.name_prefix}-lambda-s3-policy"
  description = "IAM policy for Lambda functions to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.documents.arn,
          "${aws_s3_bucket.documents.arn}/*"
        ]
      }
      ], var.enable_encryption ? [{
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = [
          data.terraform_remote_state.keys.outputs.aws_kms_key_arn
        ]
    }] : [])
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy" {
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}

#================================
# Data sources
#================================
data "aws_caller_identity" "current" {}

#================================
# Resource-based policies
#================================

resource "aws_lambda_permission" "allow_bedrock_s3_read" {
  statement_id   = "AllowBedrockInvokeS3Read"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.s3_read.function_name
  principal      = "bedrock.amazonaws.com"
  source_arn     = module.bedrock_agent.bedrock_agent[0].agent_arn
  source_account = data.aws_caller_identity.current.account_id
}

resource "aws_lambda_permission" "allow_bedrock_s3_write" {
  statement_id   = "AllowBedrockInvokeS3Write"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.s3_write.function_name
  principal      = "bedrock.amazonaws.com"
  source_arn     = module.bedrock_agent.bedrock_agent[0].agent_arn
  source_account = data.aws_caller_identity.current.account_id
}