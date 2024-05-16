# Enable the security standards that Security Hub has designated as default: 
# AWS Foundational Security Best Practices v1.0.0 and CIS AWS Foundations Benchmark v1.2.0

resource "aws_securityhub_account" "default" {
  enable_default_standards  = true
  auto_enable_controls      = true
  control_finding_generator = "SECURITY_CONTROL"
}
