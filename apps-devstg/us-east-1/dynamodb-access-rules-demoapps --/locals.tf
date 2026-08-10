locals {
  environment = replace(var.environment, "apps-", "")
  name        = "${var.project}-${local.environment}-research"

  dbname   = "${local.name}-dynamodb"
  dbengine = "dynamodb"

  cognitoname = "${local.name}-cognito"


  tags = {
    Name        = local.name
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
    CreatedBy   = "Kungfoo"
    Project     = "Research on DynamoDB access rules"
  }
}