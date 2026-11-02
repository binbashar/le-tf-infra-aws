#
# SES domain identity for the monthly cost email report
#
# Easy DKIM: SES signs with d=<ses_domain>, so DMARC aligns on DKIM even though
# the envelope MAIL FROM stays on amazonses.com. The domain is verified once the
# three CNAMEs below resolve; no _amazonses TXT record is needed.
#
resource "aws_sesv2_email_identity" "domain" {
  email_identity = var.ses_domain

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }
}

resource "aws_route53_record" "dkim" {
  provider = aws.dns
  count    = var.manage_dns_records ? 3 : 0

  zone_id = data.terraform_remote_state.dns[0].outputs.aws_public_zone_id
  name    = "${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${var.ses_domain}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}
