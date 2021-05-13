#
# CertManager policy
#
resource "aws_iam_policy" "demoapps_cert_manager" {
  name        = "demoapps-cert-manager"
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
resource "aws_iam_policy" "demoapps_external_dns_private" {
  name        = "demoapps-external-dns-private"
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
# AWS ES Proxy
#
resource "aws_iam_policy" "demoapps_aws_es_proxy" {
  name        = "demoapps-aws-es-proxy"
  description = "AWS ES Proxy permissions on AWS ElasticSearch"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "es:*",
            "Resource": "arn:aws:es:us-east-1:763606934258:domain/es-aws-binbash/*"
        }
    ]
}
EOF
}
