#
# DNS
#

#
# Public Hosted Zones
#
resource "aws_route53_zone" "aws_public_hosted_zone_1" {
  name = var.aws_public_hosted_zone_fqdn_1

  tags = local.tags
}

#
# MX records
#
resource "aws_route53_record" "aws_public_hosted_zone_1_mx_records" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = var.aws_public_hosted_zone_fqdn_1
  type    = "MX"
  ttl     = 300

  records = [
    var.aws_public_hosted_zone_1_mail_servers_1,
    var.aws_public_hosted_zone_1_mail_servers_2,
    var.aws_public_hosted_zone_1_mail_servers_3,
    var.aws_public_hosted_zone_1_mail_servers_4,
    var.aws_public_hosted_zone_1_mail_servers_5,
  ]
}

#
# A records
#
resource "aws_route53_record" "pub_A_binbash_com_ar" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name     = "binbash.com.ar"
  records = ["23.236.62.147"]
  type     = "A"
  ttl     = 300
}

#
# CNAME records
#
resource "aws_route53_record" "pub_CNAME_leverage_binbash_com_ar" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = "leverage.binbash.com.ar"
  records = ["binbashar.github.io"]
  type    = "CNAME"
  ttl     = 300
}

resource "aws_route53_record" "pub_CNAME_www_binbash_com_ar" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = "www.binbash.com.ar"
  records = ["www33.wixdns.net"]
  type    = "CNAME"
  ttl     = 300
}

#
# text records
#
resource "aws_route53_record" "aws_public_hosted_zone_1_TXT_record_2" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = var.aws_public_hosted_zone_1_text_record_2_name
  type    = "TXT"
  records = [var.aws_public_hosted_zone_1_text_record_2]
  ttl     = 300
}

resource "aws_route53_record" "aws_public_hosted_zone_1_TXT_record_3" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = var.aws_public_hosted_zone_1_text_record_3_name
  type    = "TXT"
  records = [var.aws_public_hosted_zone_1_text_record_3]
  ttl     = 300
}

resource "aws_route53_record" "aws_public_hosted_zone_1_TXT_record_4" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = var.aws_public_hosted_zone_1_text_record_4_name
  type    = "TXT"
  records = [var.aws_public_hosted_zone_1_text_record_4]
  ttl     = 300
}

resource "aws_route53_record" "aws_public_hosted_zone_TXT_record_google_spf" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = "binbash.com.ar"
  type    = "TXT"
  records = ["v=spf1 include:_spf.google.com ~all"]
  ttl     = 300
}

resource "aws_route53_record" "acm_wildcard_devstg_aws_binbash_com_ar" {
  for_each = {
    for dvo in data.terraform_remote_state.vpc-apps-devstg-certificates.outputs.certificate_wildcard_devstg_aws_binbash_com_ar_domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = aws_route53_zone.aws_public_hosted_zone_1.id
  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 300
}
