#==============================================================================
# AMAZON ELASTICSEARCH SERVICE
#==============================================================================
variable "prefix" {
  type        = string
  description = "Prefix"
  default     = "infra"
}

variable "name" {
  type        = string
  description = "Name"
  default     = "managed-eskibana"
}
