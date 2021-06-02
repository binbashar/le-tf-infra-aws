#
# ACM Cert generation with DNS validation
#
resource "aws_acm_certificate" "binbash_com_ar" {
  domain_name               = "*.${local.public_domain_name}"
  subject_alternative_names = [local.public_domain_name]
  validation_method         = "DNS"

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# AWS Provider > 0.31.1 changes
# https://github.com/hashicorp/terraform/issues/26043
# https://github.com/hashicorp/terraform-provider-aws/issues/10098#issuecomment-663562342
resource "aws_acm_certificate_validation" "binbash_com_ar" {
  certificate_arn         = aws_acm_certificate.binbash_com_ar.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_binbash_com_ar : record.fqdn]
}

# Here we need a different AWS provider because CloudFront certificates
# DNS validation records needs to be created in binbash-shared account
#
# binbash-shared route53 cross-account ACM dns validation update
# AWS Provider > 0.31.1 changes
# https://github.com/hashicorp/terraform/issues/26043
# https://github.com/hashicorp/terraform-provider-aws/issues/10098#issuecomment-663562342
resource "aws_route53_record" "cert_validation_binbash_com_ar" {
  provider = aws.shared-route53

  for_each = {
    for dvo in aws_acm_certificate.aws_binbash_com_ar.domain_validation_options : dvo.domain_name => {
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
