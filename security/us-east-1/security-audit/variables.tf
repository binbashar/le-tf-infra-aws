#===========================================#
# Security                                  #
#===========================================#
variable "lifecycle_rule_enabled" {
  type        = bool
  description = "Enable lifecycle events on this bucket"
  default     = true
}

variable "metric_namespace" {
  type        = string
  description = "A namespace for grouping all of the metrics together"
  default     = "CISBenchmark"
}

variable "create_dashboard" {
  type        = bool
  description = "When true a dashboard that displays the statistics as a line graph will be created in CloudWatch"
  default     = true
}

variable "metrics" {
  type        = any
  description = "Metrics definitions"
  default     = {}
}

variable "alarm_suffix" {
  type        = string
  description = "Alarm name suffix. You can use it to separate different AWS account. Set to `null` to avoid adding a suffix."
  default     = null
}
