#
# SES Domain Identity for binbash.co in apps-prd account
#
resource "aws_ses_domain_identity" "binbash_co" {
  domain = var.ses_domain
}

#
# DKIM for domain verification
#
resource "aws_ses_domain_dkim" "binbash_co" {
  domain = aws_ses_domain_identity.binbash_co.domain
}

#
# DNS records for SES domain verification (in shared account DNS zone)
#
resource "aws_route53_record" "ses_verification" {
  provider = aws.shared-route53
  zone_id  = data.terraform_remote_state.dns-binbash-co.outputs.public_zone_id
  name     = "_amazonses.${var.ses_domain}"
  type     = "TXT"
  ttl      = 600
  records  = [aws_ses_domain_identity.binbash_co.verification_token]
}

resource "aws_ses_domain_identity_verification" "binbash_co" {
  domain = aws_ses_domain_identity.binbash_co.id

  depends_on = [aws_route53_record.ses_verification]
}

resource "aws_route53_record" "ses_dkim" {
  provider = aws.shared-route53
  count    = 3
  zone_id  = data.terraform_remote_state.dns-binbash-co.outputs.public_zone_id
  name     = "${aws_ses_domain_dkim.binbash_co.dkim_tokens[count.index]}._domainkey"
  type     = "CNAME"
  ttl      = 600
  records  = ["${aws_ses_domain_dkim.binbash_co.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

#
# SES email identity for the sender address
#
resource "aws_ses_email_identity" "sender" {
  email = var.ses_from_email
}
