#
# Fluent-bit Roles & Policies
#
module "role_fluent_bit" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v5.2.0"

  providers = {
    aws = aws.shared
  }

  create_role  = true
  role_name    = "${local.environment}-fluent-bit"
  provider_url = replace(data.terraform_remote_state.eks-cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.fluent_bit.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:monitoring-logging:fluent-bit"
  ]

  tags = local.tags_fluent_bit
}

# Update policy with the correct resource ARN
resource "aws_iam_policy" "fluent_bit" {
  provider    = aws.shared
  name        = "${local.environment}-fluent-bit"
  description = "Fluent Bit"
  tags        = local.tags_fluent_bit
  policy      = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "es:*"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}
