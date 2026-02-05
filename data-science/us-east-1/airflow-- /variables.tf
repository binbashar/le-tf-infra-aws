#=============================#
# MWAA Variables              #
#=============================#
variable "airflow_version" {
  description = "Airflow version for MWAA environment"
  type        = string
  default     = "2.10.1"
}

variable "environment_class" {
  description = "Environment class for MWAA (mw1.micro, mw1.small, mw1.medium, mw1.large, mw1.xlarge, mw1.2xlarge)"
  type        = string
  default     = "mw1.small"
}

variable "min_workers" {
  description = "Minimum number of workers"
  type        = number
  default     = 1
}

variable "max_workers" {
  description = "Maximum number of workers"
  type        = number
  default     = 10
}

variable "schedulers" {
  description = "Number of schedulers"
  type        = number
  default     = 2
}

variable "webserver_access_mode" {
  description = "Webserver access mode (PRIVATE_ONLY or PUBLIC_ONLY)"
  type        = string
  default     = "PRIVATE_ONLY"
}

variable "dag_s3_path" {
  description = "Relative path to DAG folder in S3"
  type        = string
  default     = "dags/"
}

variable "requirements_s3_path" {
  description = "Relative path to requirements.txt in S3"
  type        = string
  default     = "requirements.txt"
}

variable "plugins_s3_path" {
  description = "Relative path to plugins.zip in S3"
  type        = string
  default     = null
}

variable "enable_logging" {
  description = "Enable CloudWatch logging for all log types"
  type        = bool
  default     = true
}

variable "log_level" {
  description = "Log level for all MWAA logs (DEBUG, INFO, WARNING, ERROR, CRITICAL)"
  type        = string
  default     = "INFO"
}
