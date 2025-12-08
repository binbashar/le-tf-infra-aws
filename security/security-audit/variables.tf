#=============================#
# Settings Variables          #
#=============================#

variable "cloudtrail_settings" {
  type = object({
    name                          = optional(string, "cloudtrail-org")
    include_global_service_events = optional(bool, true)
    is_multi_region_trail         = optional(bool, true)
    is_organization_trail         = optional(bool, true)
    enable_logging                = optional(bool, true)
    enable_log_file_validation    = optional(bool, true)
    s3_bucket = object({
      name                   = string
      lifecycle_rule_enabled = optional(bool, true)
      versioning_enabled     = optional(bool, true)
      acl                    = optional(string, "private")
      expiration_days        = optional(number, 120)
    })

    tags = optional(map(string), {})
  })
  description = "CloudTrail S3 bucket settings"
}

variable "monitoring_settings" {
  type = object({
    metric = object({
      namespace        = string
      create_dashboard = optional(bool, true)
      metrics          = optional(list(any), [])
      alarm_suffix     = optional(string, null)
    })
    logs = object({
      group_name        = optional(string, "cloudtrail")
      retention_in_days = optional(number, 14)
    })
  })
  description = "Monitoring, metrics and alarms settings for CloudTrail"
}

variable "project" {
  type    = string
  default = "tst"
}

variable "environment" {
  type = string
}

variable "profile" {
  type = string
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "accounts" {
  type = object({
    security = object({
      id = string
    })
  })
  description = "Accounts"
}
