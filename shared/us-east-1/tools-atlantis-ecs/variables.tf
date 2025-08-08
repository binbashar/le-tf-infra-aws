variable "create" {
  description = "Controls if resources should be created (affects nearly all resources)"
  type        = bool
  default     = false
}

variable "name" {
  type        = string
  description = "Name"
  default     = "atlantis"
}
