#
# Route 53 alias records pointing binbash.co and www.binbash.co at this
# CloudFront distribution. THIS IS THE CUTOVER — creating these is what takes
# the marketing site off Wix.
#
# The public binbash.co zone lives in the binbash-shared account, hence the
# aws.shared-route53 provider.
#
# GATED ON PURPOSE. var.dns_cutover_enabled defaults to false so this layer can
# be applied, deployed to and verified end-to-end on the distribution's own
# *.cloudfront.net domain without moving any live traffic. Flip it to true only
# as the deliberate cutover step.
#
# ORDERING — the shared base-dns layer currently owns both names and must give
# them up FIRST:
#
#   shared/global/base-dns/binbash.co/zone_public_binbash.co.tf
#     aws_route53_record.CNAME_www_binbash_co  -> www.binbash.co  CNAME pointing.wixdns.net
#     aws_route53_record.A_binbash_co          -> binbash.co      A     185.230.63.107 (Wix)
#
# A CNAME cannot coexist with the A/AAAA alias records below at the same name,
# so www is a destroy-then-create, not an in-place update. Remove both records
# from that layer and apply it, then apply this one. Between the two applies
# the names do not resolve; with their 300s TTL, plan for a short window and do
# it deliberately rather than discovering it mid-apply.
#
# Note the apex MX (Google Workspace) and TXT records in that layer are a
# different record type at the same name and are NOT affected — email keeps
# working across the cutover.
#
resource "aws_route53_record" "pub_A_binbash_web" {
  for_each = var.dns_cutover_enabled ? toset(local.app_aliases) : toset([])

  provider = aws.shared-route53
  zone_id  = data.terraform_remote_state.dns-binbash-co.outputs.public_zone_id
  name     = each.value
  type     = "A"

  alias {
    evaluate_target_health = false
    name                   = module.binbash_web.cf_domain_name
    zone_id                = module.binbash_web.cf_hosted_zone_id
  }
}

resource "aws_route53_record" "pub_AAAA_binbash_web" {
  for_each = var.dns_cutover_enabled ? toset(local.app_aliases) : toset([])

  provider = aws.shared-route53
  zone_id  = data.terraform_remote_state.dns-binbash-co.outputs.public_zone_id
  name     = each.value
  type     = "AAAA"

  alias {
    evaluate_target_health = false
    name                   = module.binbash_web.cf_domain_name
    zone_id                = module.binbash_web.cf_hosted_zone_id
  }
}
