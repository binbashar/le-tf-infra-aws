#
# ElasticSearch/Kibana Instance Profile, Role and Permissions
#
resource "aws_iam_instance_profile" "elasticsearch_kibana" {
  name = "elasticsearch-kibana-profile"
  role = aws_iam_role.elasticsearch_kibana.name
}

resource "aws_iam_role" "elasticsearch_kibana" {
  name = "elasticsearch-kibana-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "elasticsearch_kibana" {
  name        = "elasticsearch-kibana-policy"
  description = "Access policy for ElasticSearch & Kibana"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ElasticSearchKibanaCertbotRoute53List",
      "Action": [
        "route53:ListHostedZones",
        "route53:GetChange"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "ElasticSearchKibanaCertbotRoute53Change",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:route53:::hostedzone/${data.terraform_remote_state.dns.outputs.aws_public_zone_id[0]}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "elasticsearch_kibana_role_permissions" {
  role       = aws_iam_role.elasticsearch_kibana.name
  policy_arn = aws_iam_policy.elasticsearch_kibana.arn
}
