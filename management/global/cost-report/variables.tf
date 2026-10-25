variable "report_run_schedule" {
  description = "The schedule for running the Cost Report function"
  type        = string
  default     = "cron(0 12 * * ? *)"
}

variable "report_items_length" {
  description = "How many items to show in the report."
  type        = number
  default     = 20
}

variable "report_group_by" {
  description = "How to group the items in the report."
  type        = string
  default     = "SERVICE"
}

variable "report_mover_min_usd" {
  description = "List any item whose cost moved by at least this many USD against its 7-day average, even when it is outside the top report_items_length."
  type        = number
  default     = 0.5
}

variable "report_budget_name" {
  description = "AWS Budget shown in the report's month summary (defined in management/global/cost-mgmt). Its figures are AWS Budgets' own, which may count charges the report excludes; the report labels which. Empty string to leave it out."
  type        = string
  default     = "budget-MONTHLY-management-100-percent"
}

variable "report_alert_min_usd" {
  description = "Alert on an item whose cost moved by at least this many USD against a typical day (median of the 7 days before), together with report_alert_min_pct."
  type        = number
  default     = 1
}

variable "report_alert_min_pct" {
  description = "Alert on an item whose cost moved by at least this percentage against a typical day, together with report_alert_min_usd. A cost rising from nothing passes on the USD threshold alone."
  type        = number
  default     = 30
}

variable "report_alert_mention" {
  description = "Slack mention prepended to alerts, e.g. \"<!here>\" or \"<!subteam^S0123ABC>\". Empty for none."
  type        = string
  default     = ""
}

variable "report_daily_mode" {
  description = "\"full\": the full report every day. \"compact\": a one-line message on quiet days, and the full report only when there are alerts or on report_full_report_weekday."
  type        = string
  default     = "full"

  validation {
    condition     = contains(["compact", "full"], var.report_daily_mode)
    error_message = "report_daily_mode must be \"compact\" or \"full\"."
  }
}

variable "report_full_report_weekday" {
  description = "With report_daily_mode = \"compact\": day of the week (0 = Monday, UTC) on which the full report goes out even without alerts."
  type        = number
  default     = 0

  validation {
    # an integer too: the Lambda parses it with int(), which rejects "1.5"
    condition     = var.report_full_report_weekday == floor(var.report_full_report_weekday) && var.report_full_report_weekday >= 0 && var.report_full_report_weekday <= 6
    error_message = "report_full_report_weekday must be a whole number between 0 (Monday) and 6 (Sunday)."
  }
}

variable "report_anomaly_days" {
  description = "Show Cost Anomaly Detection anomalies nobody has given feedback on that ended in the last N days, with an impact of at least report_alert_min_usd. 0 turns the section off."
  type        = number
  default     = 14

  validation {
    # AWS keeps anomalies for 90 days; an integer, since the Lambda parses it with int()
    condition     = var.report_anomaly_days == floor(var.report_anomaly_days) && var.report_anomaly_days >= 0 && var.report_anomaly_days <= 90
    error_message = "report_anomaly_days must be a whole number between 0 (off) and 90."
  }
}

variable "report_drilldown_max" {
  description = "Break down the largest N threshold alerts by linked account and usage type: one paginated Cost Explorer query per alert, $0.01 per page (at most 5 pages), on alert days only. 0 turns it off."
  type        = number
  default     = 3

  validation {
    condition     = var.report_drilldown_max == floor(var.report_drilldown_max) && var.report_drilldown_max >= 0 && var.report_drilldown_max <= 10
    error_message = "report_drilldown_max must be a whole number between 0 (off) and 10."
  }
}
