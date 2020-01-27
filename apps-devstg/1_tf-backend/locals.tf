locals {
  tags = {
    Name        = "infra-vpn-pritunl"
    Terraform   = "true"
    Environment = var.environment
  }
}