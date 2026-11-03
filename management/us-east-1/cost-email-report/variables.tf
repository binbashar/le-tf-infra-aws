#=================#
# Layer Variables #
#=================#

variable "ses_domain" {
  description = "Domain the report is sent from, verified in SES with Easy DKIM (e.g. binbash.com.ar). The sender address is any mailbox under it."
  type        = string
  default     = "binbash.com.ar"
}

variable "manage_dns_records" {
  description = "Create the DKIM CNAME records in the Route53 zone reached through the aws.dns provider. Set to false when the domain's DNS is not in Route53, and add the records from the dkim_records output by hand."
  type        = bool
  default     = true
}

#=========================#
# Report                  #
#=========================#

variable "organization_name" {
  description = "Shown in the subject and header, e.g. [binbash] AWS cost report — October 2026. Lets one mailbox tell several organizations' reports apart."
  type        = string
  default     = "binbash"
}

variable "sender" {
  description = "From address, optionally with a display name (\"FinOps <finops@example.com>\"). Must be under ses_domain."
  type        = string
  default     = "binbash FinOps <finops@binbash.com.ar>"

  validation {
    condition     = can(regex("[^<>[:space:]]+@[^<>[:space:]]+", var.sender))
    error_message = "The sender must contain an email address."
  }
}

variable "recipients" {
  description = "The installation's own mailboxes, in To. In the SES sandbox they must be under a verified domain or be verified addresses."
  type        = list(string)
  default     = ["diego.ojeda@binbash.com.ar"]

  validation {
    condition     = length(var.recipients) > 0
    error_message = "At least one recipient is required."
  }
}

variable "binbash_recipients" {
  description = "binbash's copy, in Cc, for client installations whose contract includes it (e.g. [\"finops@binbash.com.ar\"]). Empty in binbash's own installation."
  type        = list(string)
  default     = []
}

variable "binbash_reporting_until" {
  description = "Last day (YYYY-MM-DD, inclusive) binbash_recipients are copied: the contract's end. Required when binbash_recipients is set."
  type        = string
  default     = ""

  validation {
    condition = (
      var.binbash_reporting_until == ""
      ? length(var.binbash_recipients) == 0
      : can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.binbash_reporting_until)) && can(formatdate("YYYY-MM-DD", "${var.binbash_reporting_until}T00:00:00Z"))
    )
    error_message = "Use a real date, YYYY-MM-DD. It is required when binbash_recipients is set."
  }
}

variable "schedule_expression" {
  description = "When the report is sent (UTC). The 5th leaves time for month-end support, tax and Savings Plans charges to post."
  type        = string
  default     = "cron(0 12 5 * ? *)"
}

variable "budget_name" {
  description = "AWS Budget shown in the summary (empty: none)."
  type        = string
  default     = "budget-MONTHLY-management-100-percent"
}

variable "change_min_usd" {
  description = "Changes smaller than this (USD) are not colored or listed as top increases."
  type        = number
  default     = 1
}

variable "top_n" {
  description = "How many services and accounts the summary lists."
  type        = number
  default     = 3

  validation {
    condition     = var.top_n >= 1 && floor(var.top_n) == var.top_n
    error_message = "Use a whole number, 1 or more."
  }
}

variable "anomaly_min_usd" {
  description = "Cost Anomaly Detection anomalies with less total impact (USD) are left out."
  type        = number
  default     = 10
}

variable "untagged_tag_key" {
  description = "Cost allocation tag whose missing value counts as untagged spend in the summary (empty: not shown). The tag must be activated in Billing."
  type        = string
  default     = ""
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic the errors alarm notifies. Empty: the monitoring topic from this account's notifications layer."
  type        = string
  default     = ""
}
