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
