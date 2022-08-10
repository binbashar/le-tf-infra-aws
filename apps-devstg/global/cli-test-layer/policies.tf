#
# Policies attached to Roles
#

#
# Leverage CLI Testing Policy: Bogus Policy
#
resource "aws_iam_policy" "leverage_test" {
  name        = "leverage_test"
  description = "Bogus policy for testing Leverage CLI"

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
