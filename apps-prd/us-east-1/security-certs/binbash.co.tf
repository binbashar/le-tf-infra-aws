# Create an ACM certificate for the binbash.co production site
# (us-east-1 is required for CloudFront viewer certificates)
#
# Covers the apex and www, which are the two names the binbash-web CloudFront
# distribution serves once DNS cuts over from Wix. Both are listed because a
# CloudFront viewer certificate must cover every alias on the distribution, and
# the apex and www are separate names to TLS — a certificate for one does not
# validate the other.
#
# Consumed by apps-prd/us-east-1/app-binbash-web via terraform_remote_state.
resource "aws_acm_certificate" "binbash_web" {
  domain_name               = "binbash.co"
  subject_alternative_names = ["www.binbash.co"]
  validation_method         = "DNS"
  tags                      = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Create validation records in the shared account binbash.co Route 53 zone.
#
# Keyed by domain_name so the apex and www each get their record; ACM can return
# a duplicate option when a SAN matches the domain name, and keying this way
# collapses it rather than failing on a duplicate resource address.
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
#
# Issuing this certificate is safe to do well ahead of the DNS cutover: it only
# adds _acme-style CNAME validation records, and does not move any traffic.
resource "aws_acm_certificate_validation" "binbash_web" {
  certificate_arn = aws_acm_certificate.binbash_web.arn
  validation_record_fqdns = [
    for record in aws_route53_record.binbash_web : record.fqdn
  ]
}
