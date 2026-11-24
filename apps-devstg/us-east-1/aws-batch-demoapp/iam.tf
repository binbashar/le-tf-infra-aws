#=============================================#
# Execution role                              #
#=============================================#
# Used by the ECS agent to pull the image, write logs and read the job secrets.
data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    sid     = "ECSTasksAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${local.name}-execution"
  description        = "AWS Batch ${local.name} execution role (image pull, logs, secrets)"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution_secrets" {
  count = length(local.secret_values) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = length(local.secretsmanager_secret_arns) > 0 ? [1] : []

    content {
      sid       = "ReadJobSecrets"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [for arn in local.secretsmanager_secret_arns : "${arn}*"]
    }
  }

  dynamic "statement" {
    for_each = length(local.ssm_parameter_arns) > 0 ? [1] : []

    content {
      sid       = "ReadJobParameters"
      actions   = ["ssm:GetParameters"]
      resources = local.ssm_parameter_arns
    }
  }

  # Secrets encrypted with a customer managed key. The kms:ViaService condition limits
  # decryption to requests made through Secrets Manager or SSM.
  statement {
    sid       = "DecryptJobSecrets"
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "secretsmanager.${var.region}.amazonaws.com",
        "ssm.${var.region}.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role_policy" "execution_secrets" {
  count = length(local.secret_values) > 0 ? 1 : 0

  name   = "job-secrets"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution_secrets[0].json
}

#=============================================#
# Job role                                    #
#=============================================#
# The role the job's code runs with. Least privilege: nothing unless granted via var.job_role_permissions.
resource "aws_iam_role" "job" {
  name               = "${local.name}-job"
  description        = "AWS Batch ${local.name} job role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = local.tags
}

locals {
  s3_read_bucket_arns  = var.job_role_permissions.s3_read_bucket_arns
  s3_write_bucket_arns = var.job_role_permissions.s3_write_bucket_arns
  s3_all_bucket_arns   = distinct(concat(local.s3_read_bucket_arns, local.s3_write_bucket_arns))

  create_job_inline_policy = length(local.s3_all_bucket_arns) > 0 || length(var.job_role_permissions.kms_key_arns) > 0
}

data "aws_iam_policy_document" "job" {
  count = local.create_job_inline_policy ? 1 : 0

  dynamic "statement" {
    for_each = length(local.s3_all_bucket_arns) > 0 ? [1] : []

    content {
      sid       = "ListBuckets"
      actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
      resources = local.s3_all_bucket_arns
    }
  }

  dynamic "statement" {
    for_each = length(local.s3_all_bucket_arns) > 0 ? [1] : []

    content {
      sid       = "ReadObjects"
      actions   = ["s3:GetObject"]
      resources = [for arn in local.s3_all_bucket_arns : "${arn}/*"]
    }
  }

  dynamic "statement" {
    for_each = length(local.s3_write_bucket_arns) > 0 ? [1] : []

    content {
      sid       = "WriteObjects"
      actions   = ["s3:PutObject", "s3:DeleteObject", "s3:AbortMultipartUpload"]
      resources = [for arn in local.s3_write_bucket_arns : "${arn}/*"]
    }
  }

  dynamic "statement" {
    for_each = length(var.job_role_permissions.kms_key_arns) > 0 ? [1] : []

    content {
      sid       = "UseKmsKeys"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
      resources = var.job_role_permissions.kms_key_arns
    }
  }
}

resource "aws_iam_role_policy" "job" {
  count = local.create_job_inline_policy ? 1 : 0

  name   = "job-permissions"
  role   = aws_iam_role.job.id
  policy = data.aws_iam_policy_document.job[0].json
}

resource "aws_iam_role_policy_attachment" "job_managed" {
  for_each = toset(var.job_role_permissions.managed_policy_arns)

  role       = aws_iam_role.job.name
  policy_arn = each.value
}
