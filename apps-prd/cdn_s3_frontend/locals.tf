locals {
  private_domain = "aws.binbash.com.ar"
  # Removing trailing dot from domain - just to be sure :)
  private_domain_name = trimsuffix(local.private_domain, ".")

  public_domain = "binbash.com.ar"
  # Removing trailing dot from domain - just to be sure :)
  public_domain_name = trimsuffix(local.private_domain, ".")

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}
