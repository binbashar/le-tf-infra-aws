variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "lambda_timeout must be between 1 and 900 seconds"
  }
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512

  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "lambda_memory_size must be between 128 and 10240 MB"
  }
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