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
  description = <<-EOT
    CloudWatch Logs retention for BOTH log groups this layer creates: the
    Lambda's (lambda.tf) and the API's access log (api-gateway.tf). One knob on
    purpose — the two are only useful read together when tracing a submission.

    Must be one of the values aws_cloudwatch_log_group accepts (1, 3, 5, 7, 14,
    30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922,
    3288, 3653, or 0 to never expire); anything else fails at apply with an
    opaque API error rather than at plan time.
  EOT
  type        = number
  default     = 90
}

#
# CloudWatch alarms (monitoring.tf)
#

variable "alarm_send_failure_threshold" {
  description = <<-EOT
    Number of lost applications in a 5-minute period that pages Slack. Defaults
    to 1: this layer has no datastore, so a single unsent application is
    unrecoverable and there is no volume here that would make a higher floor
    worth the missed submission.
  EOT
  type        = number
  default     = 1

  validation {
    condition     = var.alarm_send_failure_threshold >= 1
    error_message = "alarm_send_failure_threshold must be at least 1."
  }
}

variable "alarm_function_error_threshold" {
  description = "Lambda invocation failures (timeout, OOM, cold-start import error) in a 5-minute period that page Slack"
  type        = number
  default     = 1

  validation {
    condition     = var.alarm_function_error_threshold >= 1
    error_message = "alarm_function_error_threshold must be at least 1."
  }
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
