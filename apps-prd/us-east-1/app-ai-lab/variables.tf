#=================#
# Layer Variables #
#=================#

variable "ses_domain" {
  description = "Domain to configure for SES sending"
  type        = string
  default     = "binbash.co"
}

variable "ses_from_email" {
  description = "Sender email address for AI Lab notifications"
  type        = string
  default     = "noreply@binbash.co"
}
