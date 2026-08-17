locals {
  # DNS — the production names this distribution serves.
  #
  # Both are on the distribution's aliases and on the ACM certificate from the
  # security-certs layer. Traffic only actually arrives once the Route 53
  # records move off Wix; see dns.tf and var.dns_cutover_enabled.
  public_domain = "binbash.co"
  app_subdomain = "www"
  app_fqdn      = "${local.app_subdomain}.${local.public_domain}"

  app_aliases = [local.app_fqdn, local.public_domain]

  # Resource naming — deliberately NOT derived from the hostname.
  #
  # app-aws-startups-accelerate names its bucket, function and role after
  # local.app_subdomain because there the subdomain *is* the app. Here the app
  # has a name of its own and the hostname is just where it happens to be
  # served, so naming resources "www" would be meaningless. Keeping app_name
  # separate also meant the bucket did not have to be recreated when this layer
  # moved from a staging hostname to the production one.
  app_name = "binbash-web"

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
}
