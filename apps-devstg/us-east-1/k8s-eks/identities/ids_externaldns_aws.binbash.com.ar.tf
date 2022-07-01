#
# "Public" ExternalDNS Roles & Policies
#
module "role_externaldns_public" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v4.24.1"

  providers = {
    aws = aws.shared
  }

  create_role  = true
  role_name    = "${local.environment}-externaldns-public"
  provider_url = replace(data.terraform_remote_state.eks-cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.externaldns_public_aws_binbash_com_ar.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:externaldns:externaldns-public"
  ]

  tags = local.tags_externaldns_public
}

resource "aws_iam_policy" "externaldns_public_aws_binbash_com_ar" {
  provider    = aws.shared
  name        = "${local.environment}-externaldns-public-aws.binbash.com.ar"
  description = "ExternalDNS permissions on aws.binbash.com.ar"
  tags        = local.tags_externaldns_public
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/${data.terraform_remote_state.shared-dns.outputs.aws_public_zone_id[0]}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

#
# "Private" ExternalDNS Roles & Policies
#
module "role_externaldns_private" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v4.24.1"

  providers = {
    aws = aws.shared
  }

  create_role  = true
  role_name    = "${local.environment}-externaldns-private"
  provider_url = replace(data.terraform_remote_state.eks-cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.externaldns_private_aws_binbash_com_ar.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:externaldns:externaldns-private"
  ]

  tags = local.tags_externaldns_private
}

resource "aws_iam_policy" "externaldns_private_aws_binbash_com_ar" {
  provider    = aws.shared
  name        = "${local.environment}-externaldns-private-aws.binbash.com.ar"
  description = "ExternalDNS permissions on aws.binbash.com.ar"
  tags        = local.tags_externaldns_private
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/${data.terraform_remote_state.shared-dns.outputs.aws_internal_zone_id[0]}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
