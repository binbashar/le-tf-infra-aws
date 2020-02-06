#
# Service Control Policies (SCP): keep in mind we are using allow lists (aka whitelisting).
#

#
# Default Service Control Policy (SCP):
# This is a default minimal policy.
#
resource "aws_organizations_policy" "default" {
  name        = "default"
  description = "Default SCP: this is a default minimal policy. Eg: security acct."

  content = <<JSON
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": [
        "aws-portal:*",
        "cloudtrail:*",
        "cloudwatch:*",
        "config:*",
        "dynamodb:*",
        "events:*",
        "guardduty:*",
        "health:*",
        "iam:*",
        "inspector:*",
        "kms:*",
        "lambda:*",
        "logs:*",
        "s3:*",
        "ssm:*",
        "support:*",
        "tag:*"
    ],
    "Resource": "*"
  }
}
JSON
}

#
# Standard Service Control Policy (SCP):
# This policy is the one that is typically used by most accounts.
#
resource "aws_organizations_policy" "standard" {
  name        = "standard"
  description = "Standard SCP: this policy is the one that is typically used by most accounts. Eg: shared, apps_devstg and apps_prd accts."

  content = <<JSON
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": [
        "acm:*",
        "athena:*",
        "autoscaling:*",
        "application-autoscaling:*",
        "aws-portal:*",
        "backup:*",
        "backup-storage:*",
        "ce:*",
        "cloudformation:*",
        "cloudfront:*",
        "cloudtrail:*",
        "cloudwatch:*",
        "config:*",
        "dynamodb:*",
        "ec2:*",
        "ecr:*",
        "ecs:*",
        "elasticloadbalancing:*",
        "events:*",
        "guardduty:*",
        "glacier:*",
        "glue:*",
        "health:*",
        "iam:*",
        "inspector:*",
        "kms:*",
        "lambda:*",
        "logs:*",
        "redshift:*",
        "rds:*",
        "route53:*",
        "route53domains:*",
        "route53resolver:*",
        "s3:*",
        "secretsmanager:*",
        "shield:*",
        "sns:*",
        "sqs:*",
        "ssm:*",
        "support:*",
        "tag:*",
        "waf:*",
        "waf-regional:*"
    ],
    "Resource": "*"
  }
}
JSON
}
