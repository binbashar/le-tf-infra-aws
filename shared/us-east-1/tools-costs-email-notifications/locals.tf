locals {
  lambda_function_name = "MonthlyServicesUsage"

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
}
