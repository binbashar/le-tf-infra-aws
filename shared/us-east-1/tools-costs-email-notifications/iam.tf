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
        Sid = "CloudWatchLogsAccess"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.region}:${var.accounts.shared.id}:log-group:/aws/lambda/${local.lambda_function_name}",
          "arn:aws:logs:${var.region}:${var.accounts.shared.id}:log-group:/aws/lambda/${local.lambda_function_name}:*"
        ]
        Effect = "Allow"
      },
      {
        Sid = "SESAccess"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = [
          for email in distinct(concat(var.recipient_emails, [var.sender_email])) : "arn:aws:ses:${var.region}:${var.accounts.shared.id}:identity/${email}"
        ]
        Effect = "Allow"
      },
      {
        Sid = "OrganizationsReadAccess"
        Action = [
          "organizations:ListAccounts",
          "organizations:DescribeAccount"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Sid = "AssumeRoleForCostExplorer"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = "arn:aws:iam::*:role/LambdaCostsExplorerAccess"
        Effect   = "Allow"
      }

    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_role" {
  policy_arn = aws_iam_policy.monthly_services_usage_lambda_role_policy.arn
  role       = aws_iam_role.monthly_services_usage_lambda_role.name
}