#
# Policies attached to Groups
#

#
# Policy: Standard AWS Console User Security Account
#
resource "aws_iam_policy" "standard_console_user" {
  name        = "standard_console_user"
  description = "Base policy for AWS console users"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetAccountPasswordPolicy",
                "iam:ListAccountAliases",
                "iam:ListUsers",
                "iam:GetLoginProfile",
                "iam:GetAccountSummary"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:*AccessKey*",
                "iam:*SigningCertificate*",
                "iam:GetUser",
                "iam:ChangePassword",
                "iam:*ServiceSpecificCredential*",
                "iam:UpdateLoginProfile",
                "iam:*MFA*"
            ],
            "Resource": [
                "arn:aws:iam::*:user/$${aws:username}",
                "arn:aws:iam::*:mfa/$${aws:username}"
            ]
        }
    ]
}
EOF
}
