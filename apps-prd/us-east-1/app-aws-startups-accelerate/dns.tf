#
# Route53 alias records for the CloudFront distribution.
#
# Here we need a different AWS provider because the public binbash.co zone
# lives in the binbash-shared account.
#
resource "aws_route53_record" "pub_A_aws_startups_accelerate" {
  provider = aws.shared-route53
  zone_id  = data.terraform_remote_state.dns-binbash-co.outputs.public_zone_id
  name     = local.app_fqdn
  type     = "A"

  alias {
    evaluate_target_health = false
    name                   = module.aws_startups_accelerate.cf_domain_name
    zone_id                = module.aws_startups_accelerate.cf_hosted_zone_id
  }
}

resource "aws_route53_record" "pub_AAAA_aws_startups_accelerate" {
  provider = aws.shared-route53
  zone_id  = data.terraform_remote_state.dns-binbash-co.outputs.public_zone_id
  name     = local.app_fqdn
  type     = "AAAA"

  alias {
    evaluate_target_health = false
    name                   = module.aws_startups_accelerate.cf_domain_name
    zone_id                = module.aws_startups_accelerate.cf_hosted_zone_id
  }
}
