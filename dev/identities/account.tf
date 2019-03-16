#
# Account Resources
#
resource "aws_iam_account_alias" "alias" {
    account_alias = "${var.project}-apps-${var.environment}"
}