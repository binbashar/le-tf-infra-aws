variable "provisioned" {
  type        = bool
  default     = false
  description = <<-EOT
    Whether the layer creates its test resources. Its code and its infrastructure must
    match (GitOps), so master keeps it false: a test that needs resources flips the
    default to true in a PR and applies it with /tofu apply. The Leverage CLI integration
    test (binbashar/leverage, job integration_tests_cli_refarch) instead passes
    -var=provisioned=true to create and destroy them within a single run.
  EOT
}
