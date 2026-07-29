#
# Public Hosted Zones
#
resource "aws_route53_zone" "public" {
  name = var.public_hosted_zone_fqdn
  tags = local.tags
}

#
# A records
#
resource "aws_route53_record" "A_binbash_co" {
  zone_id = aws_route53_zone.public.id
  name    = "binbash.co"
  records = ["185.230.63.107"]
  type    = "A"
  ttl     = 300
}

#
# CNAME records
#
resource "aws_route53_record" "CNAME_www_binbash_co" {
  zone_id = aws_route53_zone.public.id
  name    = "www.binbash.co"
  records = ["pointing.wixdns.net"]
  type    = "CNAME"
  ttl     = 300
}

resource "aws_route53_record" "CNAME_leverage_binbash_co" {
  zone_id = aws_route53_zone.public.id
  name    = "leverage.binbash.co"
  records = ["binbashar.github.io"]
  type    = "CNAME"
  ttl     = 300
}

resource "aws_route53_record" "CNAME_ai_lab_binbash_co" {
  zone_id = aws_route53_zone.public.id
  name    = "ai-lab.binbash.co"
  records = ["98dad776b81543bb.vercel-dns-016.com."]
  type    = "CNAME"
  ttl     = 300
}

resource "aws_route53_record" "CNAME_mkt_studio_binbash_co" {
  zone_id = aws_route53_zone.public.id
  name    = "mkt-studio.binbash.co"
  records = ["c86285d79d05996d.vercel-dns-016.com."]
  type    = "CNAME"
  ttl     = 300
}

#
# Vercel-hosted endpoints. Each hostname is issued its own CNAME target, so
# the two values differ by design and are not interchangeable.
#
resource "aws_route53_record" "CNAME_hq_binbash_co" {
  zone_id = aws_route53_zone.public.id
  name    = "hq.binbash.co"
  records = ["7c298364b5aed262.vercel-dns-017.com."]
  type    = "CNAME"
  ttl     = 300
}

# NOTE: created out-of-band before being codified here, then imported into
# state. Its value is intentionally written without the trailing dot to match
# what Route 53 already holds — adding one would rewrite a live record for no
# functional gain. Other records in this zone are dot-less for the same reason.
resource "aws_route53_record" "CNAME_investor_binbash_co" {
  zone_id = aws_route53_zone.public.id
  name    = "investor.binbash.co"
  records = ["a8cf64c6e339687a.vercel-dns-017.com"]
  type    = "CNAME"
  ttl     = 300
}

#
# MX records
#
resource "aws_route53_record" "MX_gmail_binbash_co" {
  zone_id = aws_route53_zone.public.id
  name    = "binbash.co"
  type    = "MX"
  ttl     = 300

  records = [
    "1 ASPMX.L.GOOGLE.COM.",
    "5 ALT1.ASPMX.L.GOOGLE.COM.",
    "5 ALT2.ASPMX.L.GOOGLE.COM.",
    "10 ALT3.ASPMX.L.GOOGLE.COM.",
    "10 ALT4.ASPMX.L.GOOGLE.COM.",
  ]
}

#
# TXT records
#
resource "aws_route53_record" "TXT_github_binbash_co" {
  zone_id = aws_route53_zone.public.id
  name    = "_github-pages-challenge-binbashar.binbash.co"
  type    = "TXT"
  records = ["04280fb64e272af382fab1aa4a2174"]
  ttl     = 300
}

#
# TXT records
#
resource "aws_route53_record" "TXT_google_domain_verification" {
  zone_id = aws_route53_zone.public.id
  name    = "binbash.co"
  type    = "TXT"
  records = [
    "google-site-verification=7-ckJxbKpPRrcQ-foy3UIkImTGlp60MUtDgzfudJZmM",
    "linkedin-site-verification=bbe1c109-7cab-456f-9669-2f66982d41bf",
  ]
  ttl = 300
}
