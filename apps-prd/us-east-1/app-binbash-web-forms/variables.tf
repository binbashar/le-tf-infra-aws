#=================#
# Layer Variables #
#=================#

variable "ses_from_email" {
  description = <<-EOT
    Envelope sender for careers application mail. Must be an address under a
    verified SES identity in this account — binbash.co is verified with DKIM by
    the app-ai-lab layer, so any @binbash.co address works without further setup.
  EOT
  type        = string
  default     = "careers@binbash.co"

  validation {
    condition     = endswith(var.ses_from_email, "@binbash.co")
    error_message = "ses_from_email must be @binbash.co — that is the only DKIM-verified domain identity in this account."
  }
}

variable "careers_recipient" {
  description = "Hiring inbox that receives every application"
  type        = string
  default     = "people@binbash.com.ar"
}

variable "allowed_origins" {
  description = <<-EOT
    Origins allowed to POST to this API. Exactly the two names the marketing site
    is served on — a wildcard here would let any page on the internet submit
    applications through this endpoint.
  EOT
  type        = list(string)
  default     = ["https://www.binbash.co", "https://binbash.co"]

  validation {
    condition     = !contains(var.allowed_origins, "*")
    error_message = "allowed_origins must not contain '*'."
  }
}

variable "throttle_rate_limit" {
  description = <<-EOT
    Steady-state requests per second across the whole stage. CORS is a browser
    mechanism — curl or any non-browser client ignores it — so this throttle is
    the only real bound on an anonymous flood. binbash.co's SES sending quota and
    domain identity are SHARED with apps-prd/us-east-1/app-ai-lab, which sends
    production notifications; a flood here would eat into that quota and could
    throttle a different production system's mail. 1 rps is ample for a careers
    form and keeps worst-case sustained volume small relative to a typical
    graduated-account SES quota.
  EOT
  type        = number
  default     = 1
}

variable "throttle_burst_limit" {
  description = "Burst capacity across the whole stage"
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the Lambda's log group"
  type        = number
  default     = 90
}

variable "ses_sandbox" {
  description = <<-EOT
    Whether this account is still in the SES sandbox. When true, ses.tf declares
    an aws_ses_email_identity for var.careers_recipient, which a human must then
    verify by clicking the emailed link — without it, mail to that address is
    rejected outright.

    Check with: aws ses get-send-quota --region us-east-1
    Max24HourSend == 200.0 means sandboxed.
  EOT
  type        = bool
  default     = false
}
