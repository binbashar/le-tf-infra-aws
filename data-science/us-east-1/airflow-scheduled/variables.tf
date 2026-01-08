#=============================#
# EventBridge Scheduler Vars  #
#=============================#
variable "schedules" {
  description = "Map of EventBridge Scheduler schedules for creating MWAA environments"
  type = map(object({
    description         = string
    schedule_expression = string
    dag_s3_path         = optional(string, "dags/")
    execution_role_arn  = optional(string, null)
    source_bucket_arn   = string
    subnet_ids          = list(string)
    security_group_ids  = list(string)
    environment_class   = optional(string, "mw1.small")
    airflow_version     = optional(string, "2.10.1")
    max_workers         = optional(number, 10)
    min_workers         = optional(number, 1)
    schedulers          = optional(number, 2)
    webserver_access_mode = optional(string, "PRIVATE_ONLY")
    weekly_maintenance_window_start = optional(string, null)
    airflow_configuration_options = optional(map(string), {})
    enabled             = optional(bool, true)
    timezone            = optional(string, "UTC")
    flexible_time_window = optional(object({
      mode                      = string
      maximum_window_in_minutes = optional(number)
    }), { mode = "OFF" })
  }))
  default = {}
}

variable "create_scheduler_role" {
  description = "Create IAM role for EventBridge Scheduler to invoke MWAA CreateEnvironment"
  type        = bool
  default     = true
}
