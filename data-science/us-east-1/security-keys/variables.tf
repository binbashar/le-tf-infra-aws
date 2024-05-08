variable "kms_key_name" {
  type        = string
  description = "KMS key solution name, e.g. 'app' or 'jenkins'"
  default     = "kms"
}
