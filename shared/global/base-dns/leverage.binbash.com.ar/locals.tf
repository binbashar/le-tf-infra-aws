locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = "base-dns/leverage.binbash.com.ar"
  }
}
