resource "aws_sns_topic" "AWSConfigdev" {
  name            = "AWSConfigdev"
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
      "Resource": "arn:aws:sns:us-east-1:${var.dev_account_id}:AWSConfigdev",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "${var.dev_account_id}"
        }
      }
    }
  ]
}
POLICY
}
