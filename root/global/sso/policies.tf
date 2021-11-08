# data "aws_iam_policy_document" "Automation" {
#   statement {
#     sid       = "CloudWatchReader"
#     resources = ["*"]
#     actions = [
#       "cloudwatch:Describe*",
#       "cloudwatch:List*",
#       "cloudwatch:Describe*"
#     ]
#   }

#   statement {
#     sid       = "NetworkReader"
#     resources = ["*"]
#     actions = [
#       "ec2:Describe*",
#       "vpc:Describe*"
#     ]
#   }
# }
