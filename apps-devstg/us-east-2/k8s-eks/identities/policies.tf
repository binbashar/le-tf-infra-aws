#
# CertManager policy
#
resource "aws_iam_policy" "certmanager_binbash_com_ar" {
  provider    = aws.shared
  name        = "${local.prefix}-certmanager-binbash.com.ar"
  description = "CertManager permissions on binbash.com.ar"
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
            "Resource": "arn:aws:route53:::hostedzone/${data.terraform_remote_state.dns.outputs.aws_public_zone_id[0]}"
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

#
# External DNS policy
#
resource "aws_iam_policy" "externaldns_aws_binbash_com_ar" {
  provider    = aws.shared
  name        = "${local.prefix}-externaldns-aws.binbash.com.ar"
  description = "External DNS permissions on aws.binbash.com.ar"
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
                "arn:aws:route53:::hostedzone/${data.terraform_remote_state.dns.outputs.aws_internal_zone_id[0]}"
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
# External DNS policy: binbash.com.ar
#
resource "aws_iam_policy" "externaldns_binbash_com_ar" {
  provider    = aws.shared
  name        = "${local.prefix}-externaldns-binbash.com.ar"
  description = "ExternalDNS permissions on binbash.com.ar"
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
                "arn:aws:route53:::hostedzone/${data.terraform_remote_state.dns.outputs.aws_public_zone_id[0]}"
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
