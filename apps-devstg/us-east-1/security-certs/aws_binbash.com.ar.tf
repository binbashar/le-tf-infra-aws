#
# ACM Cert generation with DNS validation
#
resource "aws_acm_certificate" "aws_binbash_com_ar" {
  domain_name       = "*.${local.domain_name}"
  validation_method = "DNS"

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# AWS Provider > 0.31.1 changes
# https://github.com/hashicorp/terraform/issues/26043
# https://github.com/hashicorp/terraform-provider-aws/issues/10098#issuecomment-663562342
resource "aws_acm_certificate_validation" "aws_binbash_com_ar" {
  certificate_arn         = aws_acm_certificate.aws_binbash_com_ar.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_wildcard_binbash_com_ar : record.fqdn]
}

# Here we need a different AWS provider because CloudFront certificates
# DNS validation records needs to be created in binbash-shared account
#
# binbash-shared route53 cross-account ACM dns validation update
#
# AWS Provider > 0.31.1 changes
# https://github.com/hashicorp/terraform/issues/26043
# https://github.com/hashicorp/terraform-provider-aws/issues/10098#issuecomment-663562342
resource "aws_route53_record" "cert_validation_wildcard_binbash_com_ar" {
  provider = aws.shared-route53

  for_each = {
    for dvo in local.domain_validation_options_aws_binbash_com_ar : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  ttl     = 60
  type    = each.value.type

  zone_id = data.terraform_remote_state.dns-shared.outputs.aws_public_zone_id[0]

}

# Avoid duplicate cert_validation records like in domain-org and *.domain.org
locals {

  domains_aws_binbash_com_ar = aws_acm_certificate.aws_binbash_com_ar.domain_validation_options

  # Get domain names as a list to be able to comapre records like domain-org to *.domain.org
  domains_names_aws_binbash_com_ar = [
    for domain in local.domains_aws_binbash_com_ar :
    domain.domain_name
  ]

  # Avoid domain-org alike records
  domain_validation_options_aws_binbash_com_ar = [
    for domain in local.domains_aws_binbash_com_ar :
    domain if !contains(local.domains_names_aws_binbash_com_ar, "*.${domain.domain_name}")
  ]
}
