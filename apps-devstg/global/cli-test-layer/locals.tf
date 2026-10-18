locals {
  # Test layer of the OpenTofu plan and apply workflows. Its code and its
  # infrastructure must match (GitOps), so a test that needs resources flips
  # this to true in a PR and applies it with /tofu apply. A comment-only change
  # plans with no changes.
  provisioned = false

  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    "aws-apn-id" = local.prm_apn_id
  }
}
