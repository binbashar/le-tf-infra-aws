#------------------------------------------------------------------------------
# Agent guard: AWS managed MCP servers
#------------------------------------------------------------------------------
# AWS adds aws:ViaAWSMCPService = true to every request an AWS managed MCP
# server forwards on someone's behalf: the AWS MCP Server behind the aws-mcp
# entry in .mcp.json, the claude.ai AWS connector, and plugins that bundle it.
# Direct API calls (console, CLI, leverage, CI) never carry the key, so this
# statement only ever applies to AI agents. It denies every AWS API call an
# agent makes through such a server, reads included, under every permission
# set that can write: Administrator, FinOps and MarketplaceAIPublisher (as
# their inline policy) and DevOps, DevOpsPrd, DataScientist, GithubAutomation,
# MarketplaceBuyer and MarketplaceAndPartnerCentral (appended to their policy
# documents below). ReadOnly and SecurityAuditor are read-only by policy.
# IAM cannot express "deny everything but reads" generically: a service prefix
# cannot be wildcarded, so "*:Get*" is invalid. The repo's aws-mcp server runs
# with --read-only and makes no API calls, so it is unaffected; narrow this
# statement before dropping that flag.
# https://docs.aws.amazon.com/agent-toolkit/latest/userguide/security_iam_id-based-policy-examples.html
data "aws_iam_policy_document" "deny_all_via_aws_mcp" {
  statement {
    sid       = "DenyAllActionsViaAWSManagedMCP"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "Bool"
      variable = "aws:ViaAWSMCPService"
      values   = ["true"]
    }
  }
}

#------------------------------------------------------------------------------
# DevOps
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "devops" {
  # A statement with a new sid in override_policy_documents is appended after
  # this document's own, so the existing statements keep their positions.
  override_policy_documents = [data.aws_iam_policy_document.deny_all_via_aws_mcp.json]

  statement {
    sid = "MultiServiceFullAccessCustom"
    actions = [
      "access-analyzer:*",
      "account:Get*",
      "account:List*",
      "acm:*",
      "airflow:*",
      "aidevops:*",
      "amplify:*",
      "aoss:*",
      "apigateway:*",
      "appconfig:*",
      "application-autoscaling:*",
      "apprunner:*",
      "appsync:*",
      "athena:*",
      "autoscaling:*",
      "aws-marketplace:*",
      "aws-portal:*",
      "backup-storage:*",
      "backup:*",
      "bedrock:*",
      "bedrock-agentcore:*",
      "billing:Get*",
      "billing:List*",
      "ce:*",
      "cloudformation:*",
      "cloudfront:*",
      "cloudshell:*",
      "cloudtrail:*",
      "cloudwatch:*",
      "codebuild:*",
      "codepipeline:*",
      "codedeploy:*",
      "codestar-connections:*",
      "codeconnections:*",
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
      "elasticache:*",
      "elasticfilesystem:*",
      "elasticloadbalancing:*",
      "es:*",
      "events:*",
      "execute-api:*",
      "finops-agent:*",
      "firehose:*",
      "fms:*",
      "freetier:*",
      "glue:*",
      "guardduty:*",
      "health:*",
      "iam:*",
      "inspector2:*",
      "kafka:*",
      "kinesis:*",
      "kms:*",
      "lakeformation:*",
      "lambda:*",
      "license-manager:*",
      "lightsail:*",
      "logs:*",
      "network-firewall:*",
      "networkmanager:*",
      "notifications:*",
      "mgn:*",
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
      "s3files:*",
      "s3vectors:*",
      "sagemaker:*",
      "scheduler:*",
      "secretsmanager:*",
      "securityhub:*",
      "servicediscovery:*",
      "servicequotas:*",
      "ses:*",
      "shield:*",
      "synthetics:*",
      "sns:*",
      "sqlworkbench:*",
      "sqs:*",
      "ssm:*",
      #
      # NOTE The sso:* application actions below are what Amazon Quick's
      # Enterprise + IAM Identity Center signup calls on the caller's behalf
      # (aws_quicksight_account_subscription in
      # data-science/us-east-1/quick-suite). quicksight:* alone is not enough:
      # CreateAccountSubscription registers an Identity Center application, so
      # without these the apply fails. They are the exact set AWS documents,
      # and they do not widen this policy's blast radius -- it already grants
      # iam:*.
      # Ref: https://docs.aws.amazon.com/quick/latest/userguide/iam-policy-examples.html
      #
      "sso:CreateApplication",
      "sso:CreateApplicationAssignment",
      "sso:DeleteApplication",
      "sso:DeleteApplicationAssignment",
      "sso:DescribeApplication",
      "sso:DescribeInstance",
      "sso:DescribeRegisteredRegions",
      "sso:GetProfile",
      "sso:ListInstances",
      "sso:PutApplicationAuthenticationMethod",
      "sso:PutApplicationGrant",
      "sso:SearchGroups",
      "states:*",
      "sts:*",
      "support:*",
      "supportplans:*",
      "synthetics:*",
      "tag:*",
      "textract:*",
      "transfer:*",
      "trustedadvisor:*",
      "uxc:*",
      "waf-regional:*",
      "waf:*",
      "wafv2:*",
      "wellarchitected:*",
      "workspaces-web:*",
      "workspaces:*",
      "pricing:*",
      "transform:*"
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
      "organizations:DeregisterDelegatedAdministrator",
      "organizations:DescribeOrganization",
      "organizations:DisableAWSServiceAccess",
      "organizations:EnableAWSServiceAccess",
      "organizations:ListAWSServiceAccessForOrganization",
      "organizations:ListAccounts",
      "organizations:ListAccountsForParent",
      "organizations:ListDelegatedAdministrators",
      "organizations:ListOrganizationalUnitsForParent",
      "organizations:ListRoots",
      "organizations:RegisterDelegatedAdministrator"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "InspectorAdministration"
    actions = [
      "inspector2:Enable",
      "inspector2:Disable",
      "inspector2:AssociateMember",
      "inspector2:DisassociateMember",
      "inspector2:UpdateOrganizationConfiguration",
      "inspector2:EnableDelegatedAdminAccount",
      "inspector2:DisableDelegatedAdminAccount"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

#------------------------------------------------------------------------------
# Github Automation
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "github_automation" {
  # Appends the agent guard defined at the top of this file.
  override_policy_documents = [data.aws_iam_policy_document.deny_all_via_aws_mcp.json]

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
# Marketplace Buyer
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "marketplace_buyer" {
  # Appends the agent guard defined at the top of this file.
  override_policy_documents = [data.aws_iam_policy_document.deny_all_via_aws_mcp.json]

  statement {
    sid = "LicenseManagerReadAccess"
    actions = [
      "license-manager:ListReceivedLicenses",
    ]
    resources = ["*"]
  }
}

#------------------------------------------------------------------------------
# Data Scientist
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "data_scientist" {
  # Appends the agent guard defined at the top of this file.
  override_policy_documents = [data.aws_iam_policy_document.deny_all_via_aws_mcp.json]

  statement {
    sid = "Default"
    actions = [
      "airflow:*",
      "amplify:*",
      "athena:*",
      "apigateway:*",
      "application-signals:*",
      "aoss:*",
      "autoscaling:*",
      "aws-marketplace:*",
      "aws-portal:*",
      "bedrock:*",
      "bedrock-agentcore:*",
      "ce:*",
      "cloudformation:*",
      "cloudshell:*",
      "cloudtrail:*",
      "cloudwatch:*",
      "codebuild:*",
      "cognito-identity:*",
      "cognito-idp:*",
      "config:*",
      "ds:*",
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
      "execute-api:*",
      "firehose:*",
      "glue:*",
      "health:*",
      "iam:*",
      "kms:*",
      "lambda:*",
      "logs:*",
      "mediaconvert:*",
      "pipes:*",
      "polly:*",
      "q:*",
      "quicksight:*",
      "ram:*",
      "rds:*",
      "redshift:*",
      "redshift-data:*",
      "redshift-serverless:*",
      "resource-explorer:*",
      "resource-explorer-2:*",
      "resource-groups:*",
      "route53:*",
      "route53domains:*",
      "route53resolver:*",
      "s3:*",
      "s3vectors:*",
      "sagemaker:*",
      "secretsmanager:*",
      "sns:*",
      "sqlworkbench:*",
      "sqs:*",
      "ssm:*",
      "states:*",
      "sts:*",
      "support:*",
      "tag:*",
      "transcribe:*",
      "xray:*"
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

data "aws_iam_policy_document" "marketplaceandpartnercentral" {
  # Appends the agent guard defined at the top of this file.
  override_policy_documents = [data.aws_iam_policy_document.deny_all_via_aws_mcp.json]

  statement {
    sid = "FullSupportAccess"
    actions = [
      "support:*",
    ]
    resources = ["*"]
  }
}
