locals {
  # DNS
  #
  # Staging hostname only. Production www.binbash.co stays on Wix until the DNS
  # cutover, which is tracked separately.
  public_domain = "binbash.co"
  app_subdomain = "www-next"
  app_fqdn      = "${local.app_subdomain}.${local.public_domain}"

  # Resource naming — deliberately NOT app_subdomain.
  #
  # app-aws-startups-accelerate names its bucket, function and role after
  # local.app_subdomain because there the subdomain *is* the app. Here the
  # staging hostname is temporary and the bucket is not: naming resources
  # "www-next" would leave "bb-apps-prd-www-next" misnamed the day DNS cuts
  # over, and renaming an S3 bucket means recreating it and re-syncing the
  # whole site. The FQDN therefore appears only in `aliases`, DNS records and
  # human-readable descriptions.
  app_name = "binbash-web"

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
}
