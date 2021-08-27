#
# Prometheus/Grafana Instance Profile, Role and Permissions
#
resource "aws_iam_instance_profile" "prometheus_grafana" {
  name = "prometheus-grafana-profile"
  role = aws_iam_role.prometheus_grafana.name
}

resource "aws_iam_role" "prometheus_grafana" {
  name = "prometheus-grafana-role"
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

resource "aws_iam_policy" "prometheus_grafana" {
  name        = "prometheus-grafana-policy"
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
        "arn:aws:route53:::hostedzone/${data.terraform_remote_state.dns.outputs.aws_public_zone_id[0]}"
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

resource "aws_iam_role_policy_attachment" "prometheus_grafana_role_permissions" {
  role       = aws_iam_role.prometheus_grafana.name
  policy_arn = aws_iam_policy.prometheus_grafana.arn
}

resource "aws_iam_policy" "prometheus_grafana_assume_role" {
  name        = "prometheus_grafana_assume_role"
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
                "arn:aws:iam::${var.appsdevstg_account_id}:role/Grafana",
                "arn:aws:iam::${var.appsprd_account_id}:role/Grafana",
                "arn:aws:iam::${var.network_account_id}:role/Grafana"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "prometheus_grafana_assume_role" {
  role       = aws_iam_role.prometheus_grafana.name
  policy_arn = aws_iam_policy.prometheus_grafana_assume_role.arn
}
