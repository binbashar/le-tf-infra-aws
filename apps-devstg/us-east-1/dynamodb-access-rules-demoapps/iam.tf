data "aws_iam_policy_document" "dynamodb_user_access" {
  statement {
    sid    = "AllowOwnerAccessToOwnData"
    effect = "Allow"

    actions = [
      "dynamodb:Query",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
    ]

    resources = [
      module.dynamodb_table.table_arn,
      "${module.dynamodb_table.table_arn}/index/*",
    ]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "dynamodb:LeadingKeys"
      values   = ["USER#$${aws:PrincipalTag/userId}"]
    }
  }
}

resource "aws_iam_role" "authenticated_role" {
  name = "CognitoAuthRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = [
          "sts:AssumeRoleWithWebIdentity",
          "sts:TagSession"
        ]
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identity_pool.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      },
    ]
  })
}

resource "aws_iam_policy" "dynamodb_policy" {
  name   = "PrivateDynamoDBPolicy"
  policy = data.aws_iam_policy_document.dynamodb_user_access.json
}

resource "aws_iam_role_policy_attachment" "auth_role_attachment" {
  role       = aws_iam_role.authenticated_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

