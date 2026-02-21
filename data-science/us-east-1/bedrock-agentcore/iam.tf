#=============================#
# Runtime IAM Role            #
#=============================#
resource "aws_iam_role" "runtime" {
  name = "${local.name_prefix}-runtime-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AssumeRolePolicy"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "bedrock-agentcore.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock-agentcore:${local.region}:${local.account_id}:*"
          }
        }
      }
    ]
  })

  tags = local.tags
}

#=============================#
# Runtime Permissions         #
#=============================#
resource "aws_iam_role_policy" "runtime_permissions" {
  name = "${local.name_prefix}-runtime-permissions"
  role = aws_iam_role.runtime.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3CodeAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
        ]
        Resource = "${aws_s3_bucket.code.arn}/*"
      },
      {
        Sid    = "CloudWatchLogsGroup"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams",
        ]
        Resource = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*"
      },
      {
        Sid    = "CloudWatchLogsDescribe"
        Effect = "Allow"
        Action = "logs:DescribeLogGroups"
        Resource = "arn:aws:logs:${local.region}:${local.account_id}:log-group:*"
      },
      {
        Sid    = "CloudWatchLogsWrite"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*:log-stream:*"
      },
      {
        Sid    = "XRayTracing"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
        ]
        Resource = "*"
      },
      {
        Sid      = "CloudWatchMetrics"
        Effect   = "Allow"
        Action   = "cloudwatch:PutMetricData"
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "bedrock-agentcore"
          }
        }
      },
      {
        Sid    = "BedrockModelInvocation"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/*",
          "arn:aws:bedrock:${local.region}:${local.account_id}:*",
        ]
      },
    ]
  })
}

#=============================#
# Service-Linked Role Policy  #
#=============================#
resource "aws_iam_role_policy" "runtime_slr" {
  name = "${local.name_prefix}-runtime-slr"
  role = aws_iam_role.runtime.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CreateBedrockAgentCoreIdentitySLR"
        Effect = "Allow"
        Action = "iam:CreateServiceLinkedRole"
        Resource = "arn:aws:iam::*:role/aws-service-role/runtime-identity.bedrock-agentcore.amazonaws.com/AWSServiceRoleForBedrockAgentCoreRuntimeIdentity"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "runtime-identity.bedrock-agentcore.amazonaws.com"
          }
        }
      },
    ]
  })
}

#=============================#
# IAM Propagation Wait        #
#=============================#
resource "time_sleep" "wait_for_iam" {
  depends_on = [
    aws_iam_role_policy.runtime_permissions,
    aws_iam_role_policy.runtime_slr,
  ]
  create_duration = "15s"
}
