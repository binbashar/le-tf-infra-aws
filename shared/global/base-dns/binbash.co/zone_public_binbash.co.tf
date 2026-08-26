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
# binbash.co (apex) and www.binbash.co previously pointed at Wix here:
#
#   A     binbash.co      185.230.63.107
#   CNAME www.binbash.co  pointing.wixdns.net
#
# Both moved to apps-prd/us-east-1/app-binbash-web/dns.tf as Route 53 ALIAS
# records for the binbash-web CloudFront distribution, as part of the migration
# off Wix (see issue #1141). They live in that layer rather than here because an
# alias record needs the distribution's domain name and hosted zone id, and
# reading those from this layer would make the two layers depend on each other
# in both directions — this layer already supplies the zone id that layer uses.
#
# Ordering, if this is ever re-done: the CNAME above had to be destroyed BEFORE
# the A/AAAA aliases could be created, because Route 53 rejects any other record
# type at a name that has a CNAME.
#
# The apex MX (Google Workspace) and TXT records below are a different record
# type at the same name and were unaffected by the cutover.
#
# CNAME records
#

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
# Vercel-hosted endpoint. Vercel issues a per-hostname CNAME target, so this
# value is specific to this hostname and is not interchangeable with another.
#
resource "aws_route53_record" "CNAME_hq_binbash_co" {
  zone_id = aws_route53_zone.public.id
  name    = "hq.binbash.co"
  records = ["7c298364b5aed262.vercel-dns-017.com."]
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
# Route 53 allows a single TXT rrset per name, so every apex verification string
# has to live in this one resource. Its name is historical (it held only the
# Google one originally) - renaming it would delete and recreate the rrset,
# briefly dropping all verifications at once, so it stays as is.
#
resource "aws_route53_record" "TXT_google_domain_verification" {
  zone_id = aws_route53_zone.public.id
  name    = "binbash.co"
  type    = "TXT"
  records = [
    "google-site-verification=7-ckJxbKpPRrcQ-foy3UIkImTGlp60MUtDgzfudJZmM",
    "linkedin-site-verification=bbe1c109-7cab-456f-9669-2f66982d41bf",
    "anthropic-domain-verification-jcv3w0=g6sw9GAekRtiZCemfuqS1lP56",
  ]
  ttl = 300
}
