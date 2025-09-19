#================================
# Lambda Layer Package
#================================

data "archive_file" "bedrock_agent_layer" {
  type        = "zip"
  source_dir  = "${path.module}/src/layers/bedrock_agent"
  output_path = "${path.module}/bedrock-agent-layer.zip"
}

#================================
# Lambda Layer
#================================

resource "aws_lambda_layer_version" "bedrock_agent_utils" {
  filename            = data.archive_file.bedrock_agent_layer.output_path
  layer_name          = "${local.name_prefix}-bedrock-agent-utils"
  compatible_runtimes = ["python3.13"]
  description         = "Utilities for Bedrock Agent action group Lambda handlers"

  source_code_hash = data.archive_file.bedrock_agent_layer.output_base64sha256
}

#================================
# Lambda Function Packages
#================================

data "archive_file" "s3_read_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambda"
  output_path = "${path.module}/s3-read-lambda.zip"
  excludes    = ["s3_write_handler.py", "__pycache__"]
}

data "archive_file" "s3_write_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambda"
  output_path = "${path.module}/s3-write-lambda.zip"
  excludes    = ["s3_read_handler.py", "__pycache__"]
}

#================================
# S3 Read Lambda Function
#================================

resource "aws_lambda_function" "s3_read" {
  filename      = data.archive_file.s3_read_lambda.output_path
  function_name = local.s3_read_lambda_name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "s3_read_handler.lambda_handler"
  runtime       = "python3.13"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size
  layers        = [aws_lambda_layer_version.bedrock_agent_utils.arn]

  source_code_hash = data.archive_file.s3_read_lambda.output_base64sha256

  environment {
    variables = {
      DOCUMENTS_BUCKET = aws_s3_bucket.documents.id
      LOG_LEVEL        = "INFO"
    }
  }

  tags = merge(local.tags, { Purpose = "bedrock-agent-s3-read" })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_s3_policy
  ]
}


#================================
# S3 Write Lambda Function
#================================

resource "aws_lambda_function" "s3_write" {
  filename      = data.archive_file.s3_write_lambda.output_path
  function_name = local.s3_write_lambda_name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "s3_write_handler.lambda_handler"
  runtime       = "python3.13"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size
  layers        = [aws_lambda_layer_version.bedrock_agent_utils.arn]

  source_code_hash = data.archive_file.s3_write_lambda.output_base64sha256

  environment {
    variables = {
      DOCUMENTS_BUCKET = aws_s3_bucket.documents.id
      LOG_LEVEL        = "INFO"
    }
  }

  tags = merge(local.tags, { Purpose = "bedrock-agent-s3-write" })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_s3_policy
  ]
}

