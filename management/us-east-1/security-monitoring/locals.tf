locals {
  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    "aws-apn-id" = local.prm_apn_id
  }

  # GuardDuty protection plans kept off: foundational detection only.
  # RUNTIME_MONITORING supersedes EKS_RUNTIME_MONITORING (they are mutually exclusive).
  guardduty_protection_plans = toset([
    "S3_DATA_EVENTS",
    "EKS_AUDIT_LOGS",
    "EBS_MALWARE_PROTECTION",
    "RDS_LOGIN_EVENTS",
    "LAMBDA_NETWORK_LOGS",
    "RUNTIME_MONITORING",
  ])
}
