locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = "base-dns/binbash.co"
  }
}
