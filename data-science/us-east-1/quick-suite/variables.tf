#===========================================#
# Amazon Quick                              #
#===========================================#
variable "quick_account_name" {
  type        = string
  description = "Amazon Quick account name. Unique across all of AWS and immutable once the subscription exists."
  default     = "binbash"
}

variable "quick_edition" {
  type        = string
  description = "Amazon Quick edition. ENTERPRISE is the edition that supports IAM Identity Center integration."
  default     = "ENTERPRISE"
}

variable "quick_notification_email" {
  type        = string
  description = "Address Amazon Quick sends account notifications to."
  default     = "aws@binbash.com.ar"
}
