variable "prefix" {
  description = "Prefix that will be used for naming resources."
  type        = string
  default     = null
}

variable "create_query_results_bucket" {
  description = "Whether to create and setup a bucket for storing Athena query results."
  type        = bool
  default     = false
}

variable "bucket_name" {
  description = "The name of the bucket where Athena query results will be stored."
  type        = string
  default     = "athena-query-results"
}

variable "athena_workgroup" {
  description = "The name of the Athena workgroup."
  type        = string
  default     = "vpc-flow-logs"
}

variable "athena_database" {
  description = "The name of the Athena database."
  type        = string
  default     = "flow_logs"
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}
