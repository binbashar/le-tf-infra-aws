variable "agent_instruction" {
  description = "Instructions for the Bedrock agent"
  type        = string
  default     = null
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "lambda_timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "lambda_memory_size must be between 128 and 10240 MB."
  }
}

variable "enable_encryption" {
  description = "Enable KMS encryption for resources"
  type        = bool
  default     = false
}

variable "foundation_model" {
  description = "Foundation model ID for the Bedrock agent"
  type        = string
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}