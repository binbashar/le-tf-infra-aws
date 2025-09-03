#================================#
# Local variables                #
#================================#
variable "backend_settings" {
  type = object({
    # Bucket Name
    bucket = object({
      key       = string
      name      = optional(string, "terraform-backend")
      delimiter = optional(string, "-")
      namespace = string
    })
    # Security
    security = object({
      acl                           = optional(string, "private")
      block_public_acls             = optional(bool, true)
      block_public_policy           = optional(bool, true)
      restrict_public_buckets       = optional(bool, true)
      enable_server_side_encryption = optional(bool, true)
      enforce_ssl_requests          = optional(bool, true)
      ignore_public_acls            = optional(bool, true)
    })
    # Replication
    replication = object({
      bucket_replication_enabled    = optional(bool, true)
      notifications_sns             = optional(bool, false)
      bucket_lifecycle_enabled      = optional(bool, false)
      billing_mode                  = optional(string, "PROVISIONED")
      enable_point_in_time_recovery = optional(bool, false)
      create_kms_key                = optional(bool, false)
    })
    # Tags
    tags = map(string)
  })
}
