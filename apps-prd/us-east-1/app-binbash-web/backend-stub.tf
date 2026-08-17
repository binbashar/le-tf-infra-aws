#
# Phase-2 placeholder (intentionally disabled).
#
# One piece of this app is known to be missing and will most likely land in
# this layer:
#
#   - Contact form backend. /contact is the one page of the Wix migration still
#     unbuilt, blocked on a form-backend decision (managed form service vs
#     API Gateway + Lambda + SES). If it lands on AWS it needs SES identities
#     and a send policy here, mirroring apps-prd/us-east-1/app-ai-lab/ses.tf.
#     Do NOT provision API resources until that decision is made.
#
#     Until it ships, /contact returns 404: the app hardcodes
#     https://www.binbash.co/contact as a placeholder pointing at the Wix form,
#     and that hostname no longer serves Wix. A row in redirects.tf can point it
#     at an interim destination without any backend at all.
#
# The cutover redirect map that this file used to list as missing now exists —
# see redirects.tf (local.wix_redirects_migrated / _retired) and the function in
# cloudfront-function.tf that serves it. Keeping that function per-app rather
# than sharing it with app-aws-startups-accelerate is what left room for it.
#
# See: https://github.com/binbashar/le-tf-infra-aws/issues/1141
#
# resource "aws_ses_domain_identity" "contact" {
#   domain = local.public_domain
#   ...
# }
