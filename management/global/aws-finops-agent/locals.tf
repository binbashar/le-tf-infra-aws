locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}
