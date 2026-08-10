#
# Phase-2 backend placeholder (intentionally disabled).
#
# The app's Phase-2 backend (accounts + cloud-synced progress + real-time agent
# status) will need IAM hooks in this layer, mirroring app-ai-lab:
#
#   - Bedrock invoke: an IAM role/policy allowing bedrock:InvokeModel /
#     bedrock:InvokeModelWithResponseStream on the approved model ARNs,
#     consumed by the (future) API compute.
#   - SES send: domain/email identities + a ses:SendEmail policy, mirroring
#     apps-prd/us-east-1/app-ai-lab/ses.tf.
#
# The API style (AppSync vs API Gateway + Lambda) is intentionally deferred —
# do NOT provision API resources here until that decision is made.
# See: https://github.com/binbashar/le-tf-infra-aws/issues/1085
#
# resource "aws_iam_role" "backend" {
#   name = "${var.project}-${var.environment}-${local.app_subdomain}-backend"
#   ...
# }
