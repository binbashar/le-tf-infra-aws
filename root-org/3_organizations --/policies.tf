#
# Policies: keep in mind we are using allow lists (aka whitelisting).
#

#
# Default Policy: this is a minimal policy.
#
resource "aws_organizations_policy" "default" {
  name = "default"

  content = <<JSON
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": [
        "aws-portal:*",
        "health:*",
        "iam:*",
        "support:*"
    ],
    "Resource": "*"
  }
}
JSON
}

#
# Standard Policy: this policy is the one that is typically used by most accounts.
#
resource "aws_organizations_policy" "standard" {
  name = "standard"

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
