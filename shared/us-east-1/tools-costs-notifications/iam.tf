resource "aws_iam_role" "monthly_services_usage_lambda_role" {
  name = "monthly-services-usage-lambdarole"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaSSMAssume"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_policy" "monthly_services_usage_lambda_role_policy" {
  name = "MonthlyServicesUsageLambdaRolePolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:DescribeLogStreams",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Action = [
          "ses:*"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          "arn:aws:iam::${var.accounts.apps-devstg.id}:role/LambdaCostsExplorerAccess",
          "arn:aws:iam::${var.accounts.apps-prd.id}:role/LambdaCostsExplorerAccess",
          "arn:aws:iam::${var.accounts.shared.id}:role/LambdaCostsExplorerAccess",
          "arn:aws:iam::${var.accounts.network.id}:role/LambdaCostsExplorerAccess",
          "arn:aws:iam::${var.accounts.security.id}:role/LambdaCostsExplorerAccess",
          "arn:aws:iam::${var.accounts.root.id}:role/LambdaCostsExplorerAccess",
          "arn:aws:iam::${var.accounts.data-science.id}:role/LambdaCostsExplorerAccess",
        ]
        Effect = "Allow"
      }

    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_role" {
  policy_arn = aws_iam_policy.monthly_services_usage_lambda_role_policy.arn
  role       = aws_iam_role.monthly_services_usage_lambda_role.name
}