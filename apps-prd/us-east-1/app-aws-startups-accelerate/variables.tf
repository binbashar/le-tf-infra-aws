#=================#
# Layer Variables #
#=================#

#
# GitHub OIDC deploy identity (consumed by the app repo CI pipeline)
#
variable "github_repository" {
  description = "GitHub repository (org/repo) allowed to assume the deploy role via OIDC"
  type        = string
  default     = "binbashar/bb-sales-tools"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must be in 'org/repo' form, with no wildcards — it scopes the OIDC trust policy sub claim."
  }
}

variable "github_branch" {
  description = "Git branch (within github_repository) allowed to assume the deploy role"
  type        = string
  default     = "main"

  validation {
    condition     = length(var.github_branch) > 0 && !can(regex("[*:?\\s]", var.github_branch))
    error_message = "github_branch must be a literal branch name (no wildcards, colons or whitespace) — it scopes the OIDC trust policy sub claim."
  }
}

variable "create_github_oidc_provider" {
  description = <<-EOT
    Whether to create the GitHub Actions OIDC identity provider in this account.
    Set to false (and the existing provider will be looked up by URL) once a
    dedicated identities layer owns it — see issue #1081.
  EOT
  type        = bool
  default     = true
}

#
# CloudWatch alarms
#
variable "alarm_5xx_error_rate_threshold" {
  description = "CloudFront 5xxErrorRate (%) threshold to trigger the alarm"
  type        = number
  default     = 5

  validation {
    condition     = var.alarm_5xx_error_rate_threshold > 0 && var.alarm_5xx_error_rate_threshold <= 100
    error_message = "alarm_5xx_error_rate_threshold is a percentage and must be in (0, 100]."
  }
}

variable "alarm_total_error_rate_threshold" {
  description = "CloudFront TotalErrorRate (%) threshold to trigger the alarm"
  type        = number
  default     = 10

  validation {
    condition     = var.alarm_total_error_rate_threshold > 0 && var.alarm_total_error_rate_threshold <= 100
    error_message = "alarm_total_error_rate_threshold is a percentage and must be in (0, 100]."
  }
}

#
# CloudFront access logs
#
variable "log_expiration_days" {
  description = "Days after which CloudFront access log objects expire"
  type        = number
  default     = 90

  validation {
    condition     = var.log_expiration_days >= 1
    error_message = "log_expiration_days must be at least 1."
  }
}
