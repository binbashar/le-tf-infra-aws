#==============================#
# Cost Mgmt                    #
#==============================#
#
# Billing cloudwatch alarm
#
variable "monthly_billing_threshold_50" {
  description = "Monthly billing threshold in dollars"
  default     = "375.0"
}

variable "monthly_billing_threshold_100" {
  description = "Monthly billing threshold in dollars"
  default     = "750.0"
}

variable "currency" {
  description = "Billing currency eg: dollars"
  default     = "USD"
}

#
# Budget
#
variable "time_unit" {
  description = "The length of time until a budget resets the actual and forecasted spend. Valid values: MONTHLY, QUARTERLY, ANNUALLY."
  type        = string
  default     = "MONTHLY"
}

variable "time_period_start" {
  description = "Time to start."
  type        = string
  default     = "2020-01-01_00:00"
}

variable "notification_threshold_50" {
  description = "% Threshold when the notification should be sent."
  type        = string
  default     = 50
}

variable "notification_threshold_75" {
  description = "% Threshold when the notification should be sent."
  type        = string
  default     = 75
}

variable "notification_threshold_100" {
  description = "% Threshold when the notification should be sent."
  type        = string
  default     = 100
}

variable "workload_budgets" {
  description = "Monthly budgets keyed by the workload's Purpose tag value; each emails its owners at 100% of actual and forecast spend"
  type = map(object({
    limit_usd = number
    emails    = list(string)
  }))
  default = {
    # Normal use is about US$2 a month (bb-ai-kb-mcp layer README, "Cost").
    "kb-mcp" = {
      limit_usd = 10
      emails    = ["alex.delossantos@binbash.com.ar"]
    }
  }
}
