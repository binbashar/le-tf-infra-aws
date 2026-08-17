#
# Phase-2 placeholder (intentionally disabled).
#
# Two pieces of this app are known to be missing and will most likely land in
# this layer, but neither is provisioned yet:
#
#   - Contact form backend. /contact is the one page of the Wix migration still
#     unbuilt, blocked on a form-backend decision (managed form service vs
#     API Gateway + Lambda + SES). If it lands on AWS it needs SES identities
#     and a send policy here, mirroring apps-prd/us-east-1/app-ai-lab/ses.tf.
#     Do NOT provision API resources until that decision is made.
#
#   - The cutover redirect map. 31 migrated routes changed path relative to Wix
#     (/venture -> /services/venture-capitals, /channel-partners ->
#     /partners/affiliate-partners, the eight /services-catalog/* children, ...)
#     plus retirements (/testimonials -> Clutch, /blog and /post/* ->
#     medium.com/binbash-inc, ...). That map has no Terraform artefact anywhere
#     yet; it becomes either a second CloudFront Function or a merge into
#     cloudfront-function.tf, which is why that function is per-app rather than
#     shared with app-aws-startups-accelerate.
#
# See: https://github.com/binbashar/le-tf-infra-aws/issues/1141
#
# resource "aws_ses_domain_identity" "contact" {
#   domain = local.public_domain
#   ...
# }
