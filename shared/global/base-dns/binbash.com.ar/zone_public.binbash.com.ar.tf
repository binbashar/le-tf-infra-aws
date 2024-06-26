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
# NS Records
# Record in the binbash.com.ar hosted zone that contains the name servers of the leverage.binbash.com.ar hosted zone.
#
resource "aws_route53_record" "ns_record_leverage_binbash_com_ar" {
  type    = "NS"
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = "leverage"
  ttl     = "86400"
  records = [
    data.terraform_remote_state.dns-shared-leverage-binbash-com-ar.outputs.public_zone_domain_ns_records[0],
    data.terraform_remote_state.dns-shared-leverage-binbash-com-ar.outputs.public_zone_domain_ns_records[1],
    data.terraform_remote_state.dns-shared-leverage-binbash-com-ar.outputs.public_zone_domain_ns_records[2],
    data.terraform_remote_state.dns-shared-leverage-binbash-com-ar.outputs.public_zone_domain_ns_records[3]
  ]
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
# Redirect binbash.com.ar to binbash.co
#
module "domain-redirect-binbash_com_ar-to-binbash_co" {
  source                  = "github.com/binbashar/terraform-aws-domain-redirect?ref=v1.0.1"
  source_hosted_zone_name = "binbash.com.ar"
  target_url              = "binbash.co"
  providers = {
    aws.us-east-1 = aws.main_region
  }
}

#
# CNAME records
#
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
# TXT records
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
