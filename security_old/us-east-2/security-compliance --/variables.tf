#===========================================#
# Replication                               #
#===========================================#
variable "enable_config_bucket_replication" {
  type        = bool
  description = "Enable Config bucket replication"
  default     = true
}
