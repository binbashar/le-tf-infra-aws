#
# Route53 alias records for the CloudFront distribution.
#
# Here we need a different AWS provider because the public binbash.co zone
# lives in the binbash-shared account.
#
# Staging hostname only — www.binbash.co and the apex keep pointing at Wix
# until the cutover, which is tracked separately.
#
resource "aws_route53_record" "pub_A_binbash_web" {
  provider = aws.shared-route53
  zone_id  = data.terraform_remote_state.dns-binbash-co.outputs.public_zone_id
  name     = local.app_fqdn
  type     = "A"

  alias {
    evaluate_target_health = false
    name                   = module.binbash_web.cf_domain_name
    zone_id                = module.binbash_web.cf_hosted_zone_id
  }
}

resource "aws_route53_record" "pub_AAAA_binbash_web" {
  provider = aws.shared-route53
  zone_id  = data.terraform_remote_state.dns-binbash-co.outputs.public_zone_id
  name     = local.app_fqdn
  type     = "AAAA"

  alias {
    evaluate_target_health = false
    name                   = module.binbash_web.cf_domain_name
    zone_id                = module.binbash_web.cf_hosted_zone_id
  }
}
