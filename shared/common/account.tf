#
# Account Resources
#
resource "aws_iam_account_alias" "alias" {
    account_alias = "${var.project}-${var.environment}"
}

data "aws_caller_identity" "current" {}