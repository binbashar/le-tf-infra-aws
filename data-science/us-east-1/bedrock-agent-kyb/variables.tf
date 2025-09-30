variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

variable "lambda_memory_size" {
  description = "Lambda function memory allocation"
  type        = number
  default     = 512
}

variable "s3_lifecycle_days" {
  description = "Days before transitioning objects to STANDARD_IA storage class"
  type        = number
  default     = 90
}

variable "s3_glacier_days" {
  description = "Days before transitioning objects to GLACIER storage class"
  type        = number
  default     = 365
}