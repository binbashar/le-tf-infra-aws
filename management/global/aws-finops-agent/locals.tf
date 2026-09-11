locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }

  account_id = data.aws_caller_identity.current.account_id
}
