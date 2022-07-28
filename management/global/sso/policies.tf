data "aws_iam_policy_document" "devops" {

  statement {
    sid = "MultiServiceFullAccessCustom"
    actions = [
      "acm:*",
      "athena:*",
      "autoscaling:*",
      "appconfig:*",
      "application-autoscaling:*",
      "apprunner:*",
      "apigateway:*",
      "aws-portal:*",
      "aws-marketplace:*",
      "backup:*",
      "backup-storage:*",
      "ce:*",
      "cloudformation:*",
      "cloudfront:*",
      "cloudtrail:*",
      "cloudwatch:*",
      "config:*",
      "compute-optimizer:*",
      "datasync:*",
      "dlm:*",
      "dynamodb:*",
      "ec2:*",
      "ecr:*",
      "ecr-public:*",
      "ecs:*",
      "eks:*",
      "elasticbeanstalk:*",
      "elasticloadbalancing:*",
      "es:*",
      "events:*",
      "glue:*",
      "guardduty:*",
      "health:*",
      "iam:*",
      "kms:*",
      "lambda:*",
      "lightsail:*",
      "logs:*",
      "network-firewall:*",
      "networkmanager:*",
      "ram:*",
      "rds:*",
      "redshift:*",
      "resource-explorer:*",
      "resource-groups:*",
      "route53:*",
      "route53domains:*",
      "route53resolver:*",
      "s3:*",
      "ses:*",
      "shield:*",
      "sns:*",
      "sqs:*",
      "ssm:*",
      "sts:*",
      "support:*",
      "tag:*",
      "transfer:*",
      "trustedadvisor:*",
      "transfer:*",
      "vpc:*",
      "waf:*",
      "wafv2:*",
      "waf-regional:*",
      "wellarchitected:*"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values = [
        "${var.region}",
        "${var.region_secondary}"
      ]
    }
  }

  statement {
    sid = "Ec2RunInstanceCustomSize"
    actions = [
      "ec2:RunInstances"
    ]
    effect = "Deny"
    resources = [
      "arn:aws:ec2:*:*:instance/*"
    ]
    condition {
      test     = "ForAnyValue:StringNotLike"
      variable = "ec2:InstanceType"
      values = [
        "*.nano",
        "*.micro",
        "*.small",
        "*.medium",
        "*.large"
      ]
    }
  }

  statement {
    sid = "RdsFullAccessCustomSize"
    actions = [
      "rds:CreateDBInstance",
      "rds:CreateDBCluster"
    ]
    effect    = "Deny"
    resources = ["arn:aws:rds:*:*:db:*"]
    condition {
      test     = "ForAnyValue:StringNotLike"
      variable = "rds:DatabaseClass"
      values = [
        "*.micro",
        "*.small",
        "*.medium",
        "*.large"
      ]
    }
  }
}

data "aws_iam_policy_document" "secops" {

  statement {
    sid = "MultiServiceFullAccessCustom"
    actions = [
      "access-analyzer:*",
      "acm:*",
      "apigateway:*",
      "appsync:*",
      "aws-portal:*",
      "backup:*",
      "backup-storage:*",
      "ce:*",
      "cloudformation:*",
      "cloudtrail:*",
      "cloudwatch:*",
      "config:*",
      "dlm:*",
      "dynamodb:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "events:*",
      "fms:*",
      "guardduty:*",
      "health:*",
      "iam:*",
      "kms:*",
      "lambda:*",
      "logs:*",
      "network-firewall:*",
      "networkmanager:*",
      "organizations:Describe*",
      "organizations:List*",
      "route53:*",
      "route53domains:*",
      "route53resolver:*",
      "s3:*",
      "sns:*",
      "ssm:*",
      "support:*",
      "tag:*",
      "trustedadvisor:*",
      "vpc:*",
      "waf:*",
      "waf-regional:*",
      "wafv2:*"

    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values = [
        "${var.region}",
        "${var.region_secondary}"
      ]
    }
  }

  statement {
    sid = "Ec2RunInstanceCustomSize"
    actions = [
      "ec2:RunInstances"
    ]
    effect = "Deny"
    resources = [
      "arn:aws:ec2:*:*:instance/*"
    ]
    condition {
      test     = "ForAnyValue:StringNotLike"
      variable = "ec2:InstanceType"
      values = [
        "*.nano",
        "*.micro",
        "*.small",
        "*.medium",
        "*.large"
      ]
    }
  }

  statement {
    sid = "RdsFullAccessCustomSize"
    actions = [
      "rds:CreateDBInstance",
      "rds:CreateDBCluster"
    ]
    effect    = "Deny"
    resources = ["arn:aws:rds:*:*:db:*"]
    condition {
      test     = "ForAnyValue:StringNotLike"
      variable = "rds:DatabaseClass"
      values = [
        "*.micro",
        "*.small",
        "*.medium",
        "*.large"
      ]
    }
  }
}

data "aws_iam_policy_document" "github_automation" {
  statement {
    sid = "NATGatewayManager"
    actions = [
      "ec2:Describe*",
      "ec2:CreateNatGateway",
      "ec2:DeleteNatGateway",
    ]
    resources = ["*"]
  }
}
