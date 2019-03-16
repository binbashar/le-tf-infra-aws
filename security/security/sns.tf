resource "aws_sns_topic" "AWSConfigsecurity" {
  name            = "AWSConfigsecurity"
  display_name    = ""
  policy          = <<POLICY
{
  "Version": "2008-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "__default_statement_ID",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "SNS:GetTopicAttributes",
        "SNS:SetTopicAttributes",
        "SNS:AddPermission",
        "SNS:RemovePermission",
        "SNS:DeleteTopic",
        "SNS:Subscribe",
        "SNS:ListSubscriptionsByTopic",
        "SNS:Publish",
        "SNS:Receive"
      ],
      "Resource": "arn:aws:sns:us-east-1:${var.security_account_id}:AWSConfigsecurity",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "${var.security_account_id}"
        }
      }
    }
  ]
}
POLICY
}
