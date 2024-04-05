#------------------------------------------------------------------------------
# DevOps
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "devops" {
  statement {
    sid = "MultiServiceFullAccessCustom"
    actions = [
      "access-analyzer:*",
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
      "ds:*",
      "dynamodb:*",
      "ec2:*",
      "ec2-instance-connect:*",
      "ecr:*",
      "ecr-public:*",
      "ecs:*",
      "elasticfilesystem:*",
      "eks:*",
      "elasticbeanstalk:*",
      "elasticloadbalancing:*",
      "elasticfilesystem:*",
      "es:*",
      "events:*",
      "glue:*",
      "guardduty:*",
      "health:*",
      "iam:*",
      "inspector2:*",
      "kafka:*",
      "kms:*",
      "lambda:*",
      "license-manager:*",
      "lightsail:*",
      "logs:*",
      "network-firewall:*",
      "networkmanager:*",
      "pipes:*",
      "q:*",
      "ram:*",
      "rds:*",
      "redshift:*",
      "resource-explorer:*",
      "resource-explorer-2:*",
      "resource-groups:*",
      "route53:*",
      "route53domains:*",
      "route53resolver:*",
      "s3:*",
      "sagemaker:*",
      "ses:*",
      "secretsmanager:*",
      "securityhub:*",
      "servicediscovery:*",
      "shield:*",
      "sns:*",
      "sqs:*",
      "ssm:*",
      "sts:*",
      "support:*",
      "synthetics:*",
      "tag:*",
      "transfer:*",
      "trustedadvisor:*",
      "transfer:*",
      "vpc:*",
      "waf:*",
      "wafv2:*",
      "waf-regional:*",
      "workspaces:*",
      "workspaces-web:*",
      "wellarchitected:*"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values = [
        "${var.region}",
        "${var.region_secondary}",
        "us-east-1", # The original region is needed to have IAM working
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
        "*.large",
        "*.xlarge"
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

#------------------------------------------------------------------------------
# Github Automation
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# Data Scientist
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "data_scientist" {
  statement {
    sid = "Default"
    actions = [
      "athena:*",
      "autoscaling:*",
      "aws-portal:*",
      "ce:*",
      "cloudformation:*",
      "cloudwatch:*",
      "config:*",
      "dynamodb:*",
      "ec2:*",
      "ecr:*",
      "ecr-public:*",
      "ecs:*",
      "eks:*",
      "elasticloadbalancing:*",
      "elasticfilesystem:*",
      "es:*",
      "events:*",
      "glue:*",
      "health:*",
      "iam:*",
      "kms:*",
      "lambda:*",
      "logs:*",
      "pipes:*",
      "q:*",
      "ram:*",
      "rds:*",
      "redshift:*",
      "resource-explorer:*",
      "resource-explorer-2:*",
      "resource-groups:*",
      "route53:*",
      "route53domains:*",
      "route53resolver:*",
      "s3:*",
      "sagemaker:*",
      "secretsmanager:*",
      "sns:*",
      "sqs:*",
      "ssm:*",
      "sts:*",
      "support:*",
      "tag:*",
      "vpc:*",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values = [
        "${var.region}",
        "${var.region_secondary}",
        "us-east-1", # The original region is needed to have IAM working
      ]
    }
  }
}
