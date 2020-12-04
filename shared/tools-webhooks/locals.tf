locals {
  tags = {
    Name        = "infra-webhooks-proxy"
    Terraform   = "true"
    Environment = var.environment
  }
}
