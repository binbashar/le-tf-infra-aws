locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

locals {
  whitelisted_ips = ["190.195.47.88/32"]
}