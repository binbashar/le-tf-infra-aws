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
  name    = "binbash.com.ar"
  records = ["23.236.62.147"]
  type    = "A"
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

resource "aws_route53_record" "pub_CNAME_sendgrid_1" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = "url5402.binbash.com.ar"
  records = ["sendgrid.net"]
  type    = "CNAME"
  ttl     = 300
}

resource "aws_route53_record" "pub_CNAME_sendgrid_2" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = "26974810.binbash.com.ar"
  records = ["sendgrid.net"]
  type    = "CNAME"
  ttl     = 300
}

resource "aws_route53_record" "pub_CNAME_sendgrid_3" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = "em8184.binbash.com.ar"
  records = ["u26974810.wl061.sendgrid.net"]
  type    = "CNAME"
  ttl     = 300
}

resource "aws_route53_record" "pub_CNAME_sendgrid_4" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = "s1._domainkey.binbash.com.ar"
  records = ["s1.domainkey.u26974810.wl061.sendgrid.net"]
  type    = "CNAME"
  ttl     = 300
}

resource "aws_route53_record" "pub_CNAME_sendgrid_5" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = "s2._domainkey.binbash.com.ar"
  records = ["s2.domainkey.u26974810.wl061.sendgrid.net"]
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
  records = ["v=spf1 include:_spf.google.com ~all", "google-site-verification=LaYgwNHSBPq2LZnpW91PQVbpCcUtVKicSPgRablVl1w"]
  ttl     = 300
}
