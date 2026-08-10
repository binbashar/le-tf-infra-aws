#
# IAM Role for ECS Blue-Green Deployments
# Required for ECS to manage ALB target groups during deployment
#
resource "aws_iam_role" "ecs_blue_green" {
  count = var.ecs_deployment_type == "BLUE_GREEN" ? 1 : 0

  name = "${local.name}-ecs-blue-green-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_blue_green" {
  count = var.ecs_deployment_type == "BLUE_GREEN" ? 1 : 0

  role       = aws_iam_role.ecs_blue_green[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForLoadBalancers"
}

#
# IAM Policies for ECS Task Execution Roles to Access Secrets Manager
# One policy per service, scoped to that service's own secrets path.
# This policy is attached to each service's task execution role created by the ECS module.
#
data "aws_iam_policy_document" "ecs_secrets_access" {
  for_each = var.service_definitions

  statement {
    sid    = "AllowSecretsManagerAccess"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [
      "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:/ecs/${local.environment}/${each.key}/*"
    ]
  }

  statement {
    sid    = "AllowSSMParameterAccess"
    effect = "Allow"

    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]

    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/ecs/${local.environment}/${each.key}/*"
    ]
  }

  statement {
    sid    = "AllowKMSDecrypt"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    # KMS key ARNs are not known at authoring time; the kms:ViaService condition
    # constrains this to decryption initiated by Secrets Manager or SSM only.
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "secretsmanager.${var.region}.amazonaws.com",
        "ssm.${var.region}.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_policy" "ecs_secrets_access" {
  for_each = var.service_definitions

  name        = "${local.name}-${each.key}-secrets-access"
  description = "Allow ${each.key} task execution role to access its own Secrets Manager and SSM secrets"
  policy      = data.aws_iam_policy_document.ecs_secrets_access[each.key].json

  tags = local.tags
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}
