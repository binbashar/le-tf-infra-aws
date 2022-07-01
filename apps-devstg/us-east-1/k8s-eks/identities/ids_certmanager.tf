#
# CertManager Roles & Policies
#
module "role_certmanager" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v4.24.1"

  providers = {
    aws = aws.shared
  }

  create_role  = true
  role_name    = "${local.environment}-certmanager"
  provider_url = replace(data.terraform_remote_state.eks-cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.certmanager_aws_binbash_com_ar.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:certmanager:certmanager"
  ]

  tags = local.tags_certmanager
}

resource "aws_iam_policy" "certmanager_aws_binbash_com_ar" {
  provider    = aws.shared
  name        = "${local.environment}-certmanager-aws.binbash.com.ar"
  description = "CertManager permissions on aws.binbash.com.ar"
  tags        = local.tags_certmanager
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "route53:GetChange",
            "Resource": "arn:aws:route53:::change/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets",
                "route53:ListResourceRecordSets"
            ],
            "Resource": "arn:aws:route53:::hostedzone/${data.terraform_remote_state.shared-dns.outputs.aws_public_zone_id[0]}"
        },
        {
            "Effect": "Allow",
            "Action": "route53:ListHostedZonesByName",
            "Resource": "*"
        }
    ]
}
EOF
}
