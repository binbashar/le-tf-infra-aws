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
}

variable "github_branch" {
  description = "Git branch (within github_repository) allowed to assume the deploy role"
  type        = string
  default     = "main"
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
}

variable "alarm_total_error_rate_threshold" {
  description = "CloudFront TotalErrorRate (%) threshold to trigger the alarm"
  type        = number
  default     = 10
}

#
# CloudFront access logs
#
variable "log_expiration_days" {
  description = "Days after which CloudFront access log objects expire"
  type        = number
  default     = 90
}
