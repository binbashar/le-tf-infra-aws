locals {
  # DNS
  public_domain = "binbash.co"
  app_subdomain = "aws-startups-accelerate"
  app_fqdn      = "${local.app_subdomain}.${local.public_domain}"

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
}
