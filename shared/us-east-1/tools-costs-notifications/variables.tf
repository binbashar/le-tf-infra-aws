#=================#
# Layer Variables #
#=================#

variable "schedule_expression" {
  description = "Schedule expressions using cron"
  type        = string
  default     = "cron(0 0 1 * ? *)" # Run on the first day of the month
}

variable "sender_email" {
  description = "Sender Email Address"
  type        = string
  default     = "jose.peinado@binbash.com.ar"
}


# comma separated email addresses
variable "recipient_emails" {
  description = "Recipient Email Addresses"
  type        = list(string)
  default = [
    "jose.peinado@binbash.com.ar"
  ]
}

# JSON encoded list of cost allocation tags (Max 3)
# For example:
# default     = {
#     "cost-center" = "machine-learning",
#     "environment" = "production"
#   }
variable "cost_allocation_tags" {
  description = "JSON encoded list of cost allocation tags (Max 3)"
  type        = map(string)
  default     = {}
}

# Toggle to include or exlude the AWS credits from the report
variable "exclude_aws_credits" {
  description = "Toggle to include or exlude the AWS credits from the report"
  type        = bool
  default     = true
}

# variable to force a starting date # e.g. 2023-08-30
variable "force_start_date" {
  description = "variable to force a starting date # e.g. 2023-08-30"
  type        = string
  default     = ""
}