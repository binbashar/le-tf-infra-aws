#
# Staging-only guardrails for www-next.binbash.co.
#
# EVERYTHING IN THIS FILE COMES OFF AT CUTOVER — in the same change that points
# production www.binbash.co at this distribution, never before, or the
# unfinished site is briefly open and indexable. The rollback is: set
# var.staging_access_gate_enabled = false (which also restores the
# TotalErrorRate alarm, see monitoring.tf), delete this file, and delete its two
# references — response_headers_policy_id in cdn.tf and the gate block in
# cloudfront-function.tf.
#
# Two distinct concerns, deliberately both present:
#
#   1. X-Robots-Tag: noindex, nofollow — keeps this build out of search indexes
#      so it never competes with the live Wix site for www.binbash.co's rankings.
#   2. HTTP Basic auth — actual access control. noindex is a request to
#      well-behaved crawlers, not a gate: this hostname is public the moment the
#      certificate is issued (ACM publishes to Certificate Transparency logs)
#      and the alias record lands in the public binbash.co zone.
#
# The credential is generated here and never written to this repository, which
# is public. Read it after apply with:
#
#   leverage tofu output -raw staging_basic_auth_password
#

#
# Access control
#
resource "random_password" "staging_basic_auth" {
  length = 32
  # Alphanumeric only: the credential is pasted into browser prompts and
  # `curl -u`, where shell-special characters are a footgun for no real entropy
  # gain (32 alphanumerics is ~190 bits).
  special = false
}

locals {
  # The exact Authorization header value the CloudFront Function compares
  # against, precomputed here so the function needs no base64 support at runtime.
  #
  # sensitive() is explicit rather than inherited: `tofu plan` output gets
  # attached to pull requests on this public repo, and this guarantees the
  # function's `code` attribute renders as (sensitive value) there.
  staging_basic_auth_header = sensitive(
    "Basic ${base64encode("${var.staging_basic_auth_username}:${random_password.staging_basic_auth.result}")}"
  )
}

#
# Search-engine exclusion
#
resource "aws_cloudfront_response_headers_policy" "staging_noindex" {
  name    = "${var.project}-${var.environment}-${local.app_name}-staging-noindex"
  comment = "Staging-only: keep ${local.app_fqdn} out of search indexes until cutover"

  custom_headers_config {
    items {
      header   = "X-Robots-Tag"
      value    = "noindex, nofollow"
      override = true
    }
  }
}
