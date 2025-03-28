#
# Prometheus/Grafana Instance Profile, Role and Permissions
#
resource "aws_iam_instance_profile" "prometheus_grafana_dr" {
  name = "prometheus-grafana-dr-profile"
  role = aws_iam_role.prometheus_grafana_dr.name
}

resource "aws_iam_role" "prometheus_grafana_dr" {
  name = "prometheus-grafana-dr-role"
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

resource "aws_iam_policy" "prometheus_grafana_dr" {
  name        = "prometheus-grafana-dr-policy"
  description = "Access policy for Prometheus & Grafana"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PrometheusGrafanaCertbotRoute53List",
      "Action": [
        "route53:ListHostedZones",
        "route53:GetChange"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "PrometheusGrafanaCertbotRoute53Change",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:route53:::hostedzone/${data.terraform_remote_state.dns.outputs.aws_public_zone_id}"
      ]
    },
    {
      "Sid": "GrafanaReadCloudWatchMetrics",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:DescribeAlarmsForMetric",
        "cloudwatch:DescribeAlarmHistory",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:ListMetrics",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:GetMetricData"
      ],
      "Resource": "*"
    },
    {
      "Sid": "GrafanaReadEC2InstancesTagsAndRegions",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeTags",
        "ec2:DescribeInstances",
        "ec2:DescribeRegions"
      ],
      "Resource": "*"
    },
    {
      "Sid": "GrafanaReadResourcesTags",
      "Effect" : "Allow",
      "Action" : "tag:GetResources",
      "Resource" : "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "prometheus_grafana_dr_role_permissions" {
  role       = aws_iam_role.prometheus_grafana_dr.name
  policy_arn = aws_iam_policy.prometheus_grafana_dr.arn
}

resource "aws_iam_policy" "prometheus_grafana_dr_assume_role" {
  name        = "prometheus-grafana-dr-assume-role"
  description = "Allow Prometheus/Grafana instance to assume Grafana role in other accounts"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
                "arn:aws:iam::${var.accounts.apps-devstg.id}:role/Grafana",
                "arn:aws:iam::${var.accounts.apps-prd.id}:role/Grafana",
                "arn:aws:iam::${var.accounts.network.id}:role/Grafana"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "prometheus_grafana_dr_assume_role" {
  role       = aws_iam_role.prometheus_grafana_dr.name
  policy_arn = aws_iam_policy.prometheus_grafana_dr_assume_role.arn
}
