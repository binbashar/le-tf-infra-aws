# Create an ACM certificate for aws-startups-accelerate.binbash.co
# (us-east-1 is required for CloudFront viewer certificates)
resource "aws_acm_certificate" "aws_startups_accelerate" {
  domain_name       = "aws-startups-accelerate.binbash.co"
  validation_method = "DNS"
  tags              = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Create validation records in the shared account binbash.co Route 53 zone
resource "aws_route53_record" "aws_startups_accelerate" {
  provider = aws.shared

  for_each = {
    for dvo in aws_acm_certificate.aws_startups_accelerate.domain_validation_options : dvo.domain_name => {
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
resource "aws_acm_certificate_validation" "aws_startups_accelerate" {
  certificate_arn = aws_acm_certificate.aws_startups_accelerate.arn
  validation_record_fqdns = [
    for record in aws_route53_record.aws_startups_accelerate : record.fqdn
  ]
}
