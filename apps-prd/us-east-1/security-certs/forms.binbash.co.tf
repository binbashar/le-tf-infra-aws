# ACM certificate for forms.binbash.co — the API Gateway custom domain serving the
# careers application form (layer apps-prd/us-east-1/app-binbash-web-forms).
#
# Lives here rather than in that layer because this is where this account keeps
# every certificate: one file per certificate plus an output, consumed by
# terraform_remote_state (see app-binbash-web/cdn.tf reading
# binbash_web_certificate_arn). us-east-1 is where it has to be anyway.
resource "aws_acm_certificate" "forms_binbash_co" {
  domain_name       = "forms.binbash.co"
  validation_method = "DNS"
  tags              = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Validation records go in the shared account's binbash.co zone.
resource "aws_route53_record" "forms_binbash_co" {
  provider = aws.shared

  for_each = {
    for dvo in aws_acm_certificate.forms_binbash_co.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 3600
  type            = each.value.type
  zone_id         = data.terraform_remote_state.shared-dns-binbash-co.outputs.public_zone_id
}

resource "aws_acm_certificate_validation" "forms_binbash_co" {
  certificate_arn = aws_acm_certificate.forms_binbash_co.arn
  validation_record_fqdns = [
    for record in aws_route53_record.forms_binbash_co : record.fqdn
  ]
}
