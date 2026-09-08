#
# Lambda execution role.
#
resource "aws_iam_role" "careers_application" {
  name = "${local.function_name}-role"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

#
# Two statements, both scoped to a named resource.
#
# ses:SendEmail is bound to the binbash.co domain identity, NOT Resource "*". A
# wildcard here would let this function send as any verified identity in the
# account, which currently includes whatever the AI Use Case Lab verifies.
#
resource "aws_iam_role_policy" "careers_application" {
  name = "${local.function_name}-policy"
  role = aws_iam_role.careers_application.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.careers_application.arn}:*"
      },
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail"]
        Resource = data.terraform_remote_state.ai-lab.outputs.ses_domain_identity_arn
        Condition = {
          StringEquals = {
            "ses:FromAddress" = var.ses_from_email
          }
        }
      }
    ]
  })
}
