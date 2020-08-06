#
# ACM Cert generation with DNS validation
#
resource "aws_acm_certificate" "binbash_com_ar" {
  domain_name       = "*.${local.public_domain_name}"
  subject_alternative_names = [local.public_domain_name]
  validation_method = "DNS"

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "binbash_com_ar" {
  certificate_arn = aws_acm_certificate.binbash_com_ar.arn
  validation_record_fqdns = [
    aws_route53_record.cert_validation_binbash_com_ar.fqdn
  ]
}

# Here we need a different AWS provider because CloudFront certificates
# DNS validation records needs to be created in binbash-shared account
#
# binbash-shared route53 cross-account ACM dns validation update
resource "aws_route53_record" "cert_validation_binbash_com_ar" {
  provider = aws.shared-route53
  name     = aws_acm_certificate.binbash_com_ar.domain_validation_options.0.resource_record_name
  type     = aws_acm_certificate.binbash_com_ar.domain_validation_options.0.resource_record_type
  zone_id  = data.terraform_remote_state.dns-shared.outputs.aws_public_zone_id[0]

  records = [
    aws_acm_certificate.binbash_com_ar.domain_validation_options.0.resource_record_value
  ]
  ttl = 60
}
