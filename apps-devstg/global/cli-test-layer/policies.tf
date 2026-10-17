#
# Policies attached to Roles
#

#
# Leverage CLI Testing Policy: Bogus Policy
#
resource "aws_iam_policy" "leverage_test" {
  count = local.provisioned ? 1 : 0

  name        = "leverage_test"
  description = "Bogus policy for testing Leverage CLI"
  tags        = local.tags

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "BogusPolicyForTesting",
            "Effect": "Allow",
            "Action": [
                "vpc:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}
