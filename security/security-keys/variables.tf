
#=============================#
# Settings Variables          #
#=============================#

variable "kms_settings" {
  type = object({
    key_name                = string
    enabled                 = optional(bool, true)
    description             = optional(string, "KMS key for the account")
    delimiter               = optional(string, "-")
    deletion_window_in_days = optional(number, 7)
    enable_key_rotation     = optional(bool, true)
    alias                   = optional(string, "")
    policy                  = optional(string, "") 
  })
  description = "KMS key settings"
}

variable "ssh_settings" {
  type = object({
    key_name   = string
    public_key = string
  })
  description = "SSH key settings"
  default     = null
}

variable "regions" {
  type = list(string)
  description = "Regions to deploy the security keys"
}

variable "project" {
  type = string
  default = "tst"
}

variable "environment" {
  type = string
}

variable "profile" {
  type = string
}

variable "accounts" {
  type = object({
    security = object({
      id = string
    })
  })
  description = "Accounts"
}
