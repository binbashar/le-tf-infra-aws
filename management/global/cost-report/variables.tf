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
