#
# External-Secrets Roles & Policies
#
module "role_external_secrets" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v5.2.0"

  providers = {
    aws = aws.shared
  }

  create_role  = true
  role_name    = "${local.environment}-external-secrets"
  provider_url = replace(data.terraform_remote_state.eks-cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.external_secrets_secrets_manager.arn,
    aws_iam_policy.external_secrets_parameter_store.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:external-secrets:external-secrets"
  ]

  tags = local.tags_external_secrets
}

resource "aws_iam_policy" "external_secrets_secrets_manager" {
  provider    = aws.shared
  name        = "${local.environment}-external-secrets-secrets-manager"
  description = "External-secrets permissions on Secrets Manager"
  tags        = local.tags_external_secrets
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecretVersionIds"
      ],
      "Resource": [
        "arn:aws:secretsmanager:${var.region}:${var.accounts.shared.id}:secret:/k8s-eks/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": [
        "${data.terraform_remote_state.shared.outputs.aws_kms_key_arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "external_secrets_parameter_store" {
  provider    = aws.shared
  name        = "${local.environment}-external-secrets-parameter-store"
  description = "External-secrets permissions on Parameter Store"
  tags        = local.tags_external_secrets
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:DescribeParameters",
        "ssm:GetParameter*"
      ],
      "Resource": [
        "arn:aws:ssm:${var.region}:${var.accounts.shared.id}:parameter/k8s-eks/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": [
        "${data.terraform_remote_state.shared.outputs.aws_kms_key_arn}"
      ]
    }
  ]
}
EOF
}
