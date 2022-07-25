# Create an ACM certificate
resource "aws_acm_certificate" "main" {
  domain_name               = "*.binbash.com.ar"
  subject_alternative_names = ["*.${local.environment}.aws.binbash.com.ar"]
  validation_method         = "DNS"
  tags                      = local.tags
}

# Create validation records in Route 53
resource "aws_route53_record" "main" {
  provider = aws.shared

  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.terraform_remote_state.shared-dns.outputs.aws_public_zone_id[0]
}

# "This resource represents a successful validation of an ACM certificate in
# concert with other resources."
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [
    for record in aws_route53_record.main : record.fqdn
  ]
}
