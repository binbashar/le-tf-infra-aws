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

#
# Delete protection policy (scp)
#
resource "aws_organizations_policy" "delete_protection" {
  name        = "delete-protection"
  description = "Delete protection"

  content = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Statement1",
      "Effect": "Deny",
      "Action": [
        "ec2:DeleteTransitGateway",
        "ec2:ModifyTransitGateway",
        "ec2:ModifyTransitGatewayVpcAttachment",
        "ec2:DeleteTransitGatewayConnectPeer",
        "ec2:DeleteTransitGatewayConnect",
        "ec2:DeleteTransitGatewayMulticastDomain",
        "ec2:DeleteTransitGatewayPeeringAttachment",
        "ec2:DeleteTransitGatewayPrefixListReference",
        "ec2:DeleteTransitGatewayRoute",
        "ec2:DeleteTransitGatewayRouteTable",
        "ec2:DeleteTransitGatewayVpcAttachment"
      ],
      "Resource": [
        "*"
      ],
      "Condition": {
        "ForAnyValue:StringEquals": {
          "aws:ResourceTag/protectFromDeletion": [
            "true"
          ]
        }
      }
    }
  ]
}
JSON
}

#
# Delete protection policy (scp)
#
resource "aws_organizations_policy" "tag_protection" {
  name        = "tag-protection"
  description = "This policy prevents all user but DevOps role to delete or modify tags on EC2, RDs and EKS resources"

  content = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Statement1",
      "Effect": "Deny",
      "Action": [
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource",
        "eks:UntagResource",
        "eks:TagResource"
      ],
      "Resource": [
        "*"
      ],
      "Condition": {
        "StringNotEquals": {
          "aws:PrincipalArn": [
            "arn:aws:iam::${aws_organizations_account.shared.id}:role/DevOps",
            "arn:aws:iam::${aws_organizations_account.network.id}:role/DevOps",
            "arn:aws:iam::${aws_organizations_account.apps_devstg.id}:role/DevOps",
            "arn:aws:iam::${aws_organizations_account.apps_prd.id}:role/DevOps"
          ]
        },
        "ForAnyValue:StringEquals": {
          "aws:TagKeys": [
            "ProtectFromDeletion"
          ]
        }
      }
    }
  ]
}
JSON
}
