data "archive_file" "bda_invoker" {
  type        = "zip"
  source_dir  = "${path.module}/src/bda-invoker"
  output_path = "${path.module}/bda-invoker.zip"
}

data "archive_file" "agent_invoker" {
  type        = "zip"
  source_dir  = "${path.module}/src/agent-invoker"
  output_path = "${path.module}/agent-invoker.zip"
}

data "archive_file" "get_documents" {
  type        = "zip"
  source_dir  = "${path.module}/src/get-documents"
  output_path = "${path.module}/get-documents.zip"
}

data "archive_file" "save_document" {
  type        = "zip"
  source_dir  = "${path.module}/src/save-document"
  output_path = "${path.module}/save-document.zip"
}

data "archive_file" "check_sanctions" {
  type        = "zip"
  source_dir  = "${path.module}/src/check-sanctions"
  output_path = "${path.module}/check-sanctions.zip"
}

resource "aws_lambda_function" "bda_invoker" {
  filename         = data.archive_file.bda_invoker.output_path
  function_name    = local.bda_invoker_name
  role             = aws_iam_role.bda_invoker_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  source_code_hash = data.archive_file.bda_invoker.output_base64sha256

  environment {
    variables = {
      BDA_PROJECT_ARN   = awscc_bedrock_data_automation_project.kyb_agent.project_arn
      INPUT_BUCKET      = aws_s3_bucket.input.id
      PROCESSING_BUCKET = aws_s3_bucket.processing.id
      LOG_LEVEL         = "INFO"
    }
  }

  tags = merge(local.tags, {
    Name = local.bda_invoker_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.bda_invoker_policy,
    aws_cloudwatch_log_group.bda_invoker_logs
  ]
}

resource "aws_lambda_function" "agent_invoker" {
  filename         = data.archive_file.agent_invoker.output_path
  function_name    = local.agent_invoker_name
  role             = aws_iam_role.agent_invoker_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  source_code_hash = data.archive_file.agent_invoker.output_base64sha256

  environment {
    variables = {
      AGENT_ID          = awscc_bedrock_agent.kyb_agent.agent_id
      AGENT_ALIAS_ID    = awscc_bedrock_agent_alias.kyb_agent_live.agent_alias_id
      PROCESSING_BUCKET = aws_s3_bucket.processing.id
      LOG_LEVEL         = "INFO"
    }
  }

  tags = merge(local.tags, {
    Name = local.agent_invoker_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.agent_invoker_policy,
    aws_cloudwatch_log_group.agent_invoker_logs
  ]
}

resource "aws_lambda_function" "get_documents" {
  filename         = data.archive_file.get_documents.output_path
  function_name    = local.get_documents_name
  role             = aws_iam_role.get_documents_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  source_code_hash = data.archive_file.get_documents.output_base64sha256

  environment {
    variables = {
      PROCESSING_BUCKET = aws_s3_bucket.processing.id
      LOG_LEVEL         = "INFO"
    }
  }

  tags = merge(local.tags, {
    Name = local.get_documents_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.get_documents_policy,
    aws_cloudwatch_log_group.get_documents_logs
  ]
}

resource "aws_lambda_function" "save_document" {
  filename         = data.archive_file.save_document.output_path
  function_name    = local.save_document_name
  role             = aws_iam_role.save_document_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  source_code_hash = data.archive_file.save_document.output_base64sha256

  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.output.id
      LOG_LEVEL     = "INFO"
    }
  }

  tags = merge(local.tags, {
    Name = local.save_document_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.save_document_policy,
    aws_cloudwatch_log_group.save_document_logs
  ]
}

resource "aws_cloudwatch_log_group" "bda_invoker_logs" {
  name              = "/aws/lambda/${local.bda_invoker_name}"
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_cloudwatch_log_group" "agent_invoker_logs" {
  name              = "/aws/lambda/${local.agent_invoker_name}"
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_cloudwatch_log_group" "get_documents_logs" {
  name              = "/aws/lambda/${local.get_documents_name}"
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_cloudwatch_log_group" "save_document_logs" {
  name              = "/aws/lambda/${local.save_document_name}"
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_lambda_function" "check_sanctions" {
  filename         = data.archive_file.check_sanctions.output_path
  function_name    = local.check_sanctions_name
  role             = aws_iam_role.check_sanctions_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  source_code_hash = data.archive_file.check_sanctions.output_base64sha256

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }

  tags = merge(local.tags, {
    Name = local.check_sanctions_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.check_sanctions_policy,
    aws_cloudwatch_log_group.check_sanctions_logs
  ]
}

resource "aws_cloudwatch_log_group" "check_sanctions_logs" {
  name              = "/aws/lambda/${local.check_sanctions_name}"
  retention_in_days = 30
  tags              = local.tags
}
