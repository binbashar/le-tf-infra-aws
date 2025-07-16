resource "aws_iam_policy" "assume_oaar_role" {
  name        = "assume_oaar_role"
  description = "Allow assume OrganizationAccountAccessRole role in member accounts"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "sts:AssumeRole"
        ],
        "Resource": [
          "arn:aws:iam::${var.accounts.management.id}:role/OrganizationAccountAccessRole",
          "arn:aws:iam::${var.accounts.security.id}:role/OrganizationAccountAccessRole",
          "arn:aws:iam::${var.accounts.shared.id}:role/OrganizationAccountAccessRole",
          "arn:aws:iam::${var.accounts.network.id}:role/OrganizationAccountAccessRole",
          "arn:aws:iam::${var.accounts.apps-devstg.id}:role/OrganizationAccountAccessRole",
          "arn:aws:iam::${var.accounts.apps-prd.id}:role/OrganizationAccountAccessRole"
        ]
      }
    ]
  }
  EOF
}
