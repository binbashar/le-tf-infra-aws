# Create an ACM certificate for www-next.binbash.co
# (us-east-1 is required for CloudFront viewer certificates)
#
# Staging hostname for the binbash-web Next.js rebuild of www.binbash.co, served
# by apps-prd/us-east-1/app-binbash-web. Production www.binbash.co keeps being
# served by Wix until the DNS cutover, which is tracked separately and needs its
# own certificate covering www.binbash.co and the apex.
resource "aws_acm_certificate" "binbash_web" {
  domain_name       = "www-next.binbash.co"
  validation_method = "DNS"
  tags              = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Create validation records in the shared account binbash.co Route 53 zone
resource "aws_route53_record" "binbash_web" {
  provider = aws.shared

  for_each = {
    for dvo in aws_acm_certificate.binbash_web.domain_validation_options : dvo.domain_name => {
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

# "This resource represents a successful validation of an ACM certificate in
# concert with other resources."
resource "aws_acm_certificate_validation" "binbash_web" {
  certificate_arn = aws_acm_certificate.binbash_web.arn
  validation_record_fqdns = [
    for record in aws_route53_record.binbash_web : record.fqdn
  ]
}
