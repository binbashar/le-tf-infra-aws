#===========================================#
# Security                                  #
#===========================================#
variable "metric_namespace" {
  type        = string
  description = "A namespace for grouping all of the metrics together"
  default     = "CISBenchmark"
}

variable "create_dashboard" {
  type        = bool
  description = "When true a dashboard that displays the statistics as a line graph will be created in CloudWatch"
  default     = false
}

variable "metrics" {
  type        = any
  description = "Metrics definitions"
  default     = {}
}

variable "create_alb_logs_bucket" {
  type        = bool
  default     = false
}
