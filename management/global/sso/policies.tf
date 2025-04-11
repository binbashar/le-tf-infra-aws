#------------------------------------------------------------------------------
# DevOps
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "devops" {
  statement {
    sid = "MultiServiceFullAccessCustom"
    actions = [
      "access-analyzer:*",
      "acm:*",
      "aoss:*",
      "aoss:*",
      "apigateway:*",
      "appconfig:*",
      "application-autoscaling:*",
      "apprunner:*",
      "athena:*",
      "autoscaling:*",
      "aws-marketplace:*",
      "aws-portal:*",
      "backup-storage:*",
      "backup:*",
      "bedrock:*",
      "ce:*",
      "cloudformation:*",
      "cloudfront:*",
      "cloudshell:*",
      "cloudtrail:*",
      "cloudwatch:*",
      "cognito-identity:*",
      "cognito-idp:*",
      "compute-optimizer:*",
      "config:*",
      "datasync:*",
      "dlm:*",
      "dms:*",
      "ds:*",
      "dynamodb:*",
      "ec2-instance-connect:*",
      "ec2:*",
      "ecr-public:*",
      "ecr:*",
      "ecs:*",
      "eks:*",
      "elasticbeanstalk:*",
      "elasticfilesystem:*",
      "elasticfilesystem:*",
      "elasticloadbalancing:*",
      "es:*",
      "events:*",
      "execute-api:*",
      "fms:*",
      "glue:*",
      "guardduty:*",
      "health:*",
      "iam:*",
      "inspector2:*",
      "kafka:*",
      "kms:*",
      "lakeformation:*",
      "lambda:*",
      "license-manager:*",
      "lightsail:*",
      "logs:*",
      "network-firewall:*",
      "networkmanager:*",
      "pipes:*",
      "q:*",
      "quicksight:*",
      "ram:*",
      "rds-data:*",
      "rds:*",
      "redshift-data:*",
      "redshift:*",
      "resource-explorer-2:*",
      "resource-explorer:*",
      "resource-groups:*",
      "route53:*",
      "route53domains:*",
      "route53resolver:*",
      "s3:*",
      "sagemaker:*",
      "scheduler:*",
      "scheduler:*",
      "secretsmanager:*",
      "securityhub:*",
      "servicediscovery:*",
      "ses:*",
      "shield:*",
      "sns:*",
      "sqlworkbench:*",
      "sqs:*",
      "ssm:*",
      "states:*",
      "sts:*",
      "support:*",
      "synthetics:*",
      "synthetics:*",
      "tag:*",
      "transfer:*",
      "transfer:*",
      "trustedadvisor:*",
      "waf-regional:*",
      "waf:*",
      "wafv2:*",
      "wellarchitected:*",
      "workspaces-web:*",
      "workspaces:*"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values = [
        "${var.region}",
        "${var.region_secondary}",
        "us-east-1", # The original region is needed to have IAM working
        "us-west-2"
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

  statement {
    sid = "OrganizationWide"
    actions = [
      "organizations:ListDelegatedAdministrators",
      "organizations:ListAccounts",
      "organizations:DescribeOrganization",
      "organizations:ListAWSServiceAccessForOrganization",
      "organizations:ListRoots",
      "organizations:ListAccountsForParent",
      "organizations:ListOrganizationalUnitsForParent"
    ]
    effect    = "Allow"
    resources = ["*"]

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
      "bedrock:*",
      "ce:*",
      "cloudformation:*",
      "cloudwatch:*",
      "cognito-identity:*",
      "cognito-idp:*",
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
      "aws-marketplace:*",
      "pipes:*",
      "q:*",
      "quicksight:*",
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
      "states:*",
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
        "us-west-2", # Requested by MLOps team in order to have access to more Bedrock models
      ]
    }
  }
}

data "aws_iam_policy_document" "marketplaceseller" {
  statement {
    sid = "FullSupportAccess"
    actions = [
      "support:*",
    ]
    resources = ["*"]
  }
}
