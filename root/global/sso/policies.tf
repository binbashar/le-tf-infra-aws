data "aws_iam_policy_document" "DeployMaster" {
  statement {
    sid       = "CloudWatchReader"
    resources = ["*"]
    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:List*",
      "cloudwatch:Describe*"
    ]
  }

  statement {
    sid       = "NetworkReader"
    resources = ["*"]
    actions = [
      "ec2:Describe*",
      "vpc:Describe*"
    ]
  }
}
