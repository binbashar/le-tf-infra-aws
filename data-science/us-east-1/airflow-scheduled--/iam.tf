#=============================#
# MWAA Execution Role         #
#=============================#
module "iam_assumable_role_mwaa_execution" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

  trusted_role_services = [
    "airflow.amazonaws.com",
    "airflow-env.amazonaws.com"
  ]

  create_role      = true
  role_name        = local.mwaa_execution_role_name
  role_description = "Execution role for MWAA environments created by EventBridge Scheduler"
  role_path        = "/"

  role_requires_mfa = false

  custom_role_policy_arns = [
    aws_iam_policy.mwaa_execution_base.arn,
    aws_iam_policy.mwaa_execution_s3.arn
  ]

  tags = local.tags
}

resource "aws_iam_policy" "mwaa_execution_base" {
  name        = "${local.mwaa_execution_role_name}-base-policy"
  description = "Base policy for MWAA execution role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "airflow:PublishMetrics"
        Resource = "arn:aws:airflow:${var.region}:${data.aws_caller_identity.current.account_id}:environment/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:GetLogRecord",
          "logs:GetLogGroupFields",
          "logs:GetQueryResults"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:airflow-*"
      },
      {
        Effect   = "Allow"
        Action   = "logs:DescribeLogGroups"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "cloudwatch:PutMetricData"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ]
        Resource = "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:airflow-celery-*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*",
          "kms:Encrypt"
        ]
        NotResource = "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*"
        Condition = {
          StringLike = {
            "kms:ViaService" = "sqs.${var.region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_policy" "mwaa_execution_s3" {
  name        = "${local.mwaa_execution_role_name}-s3-policy"
  description = "S3 access policy for MWAA execution role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject*",
          "s3:GetBucket*",
          "s3:List*",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::bb-apache-airflow-dag",
          "arn:aws:s3:::bb-apache-airflow-dag/*"
        ]
      }
    ]
  })

  tags = local.tags
}
