locals {
  domain = "binbash.com.ar"

  # Removing trailing dot from domain - just to be sure :)
  domain_name = trimsuffix(local.domain, ".")

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Name        = local.domain_name
    Layer       = local.layer_name
  }
}
