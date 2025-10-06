module "apigw_kyb_agent" {
  source = "github.com/SPHTech-Platform/terraform-aws-apigw.git?ref=v0.4.13"

  name  = "KybAgentApi"
  stage = "v1"

  body_template = templatefile("${path.module}/schemas/invoke-agent.yaml", {
    region     = var.region
    lambda_arn = aws_lambda_function.agent_invoker.arn
  })

  metrics_enabled             = true
  data_trace_enabled          = true
  enable_global_apigw_logging = true
  tags                        = local.tags

  enable_resource_policy = true
  resource_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "execute-api:Invoke"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}
