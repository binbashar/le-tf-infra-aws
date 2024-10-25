#===========================================#
# Replication                               #
#===========================================#
variable "enable_cloudtrail_bucket_replication" {
  type        = bool
  description = "Enable CloudTrail bucket replication"
  default     = false
}
