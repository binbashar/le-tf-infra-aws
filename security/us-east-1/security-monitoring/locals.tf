locals {
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

  # Every member account (all of var.accounts except this one, the delegated
  # admin, and management, whose detector its own layer manages) crossed with
  # every protection plan, keyed "<account>/<plan>".
  guardduty_member_plans = {
    for pair in setproduct(
      [for name in keys(var.accounts) : name if !contains(["security", "management"], name)],
      local.guardduty_protection_plans,
    ) : "${pair[0]}/${pair[1]}" => { account = pair[0], plan = pair[1] }
  }
}
