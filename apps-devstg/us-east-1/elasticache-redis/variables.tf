variable "engine_version" {
  description = "Version number of the redis engine to be used. If not set, defaults to the latest version"
  type        = string
  default     = "7.1"
}

variable "node_type" {
  description = "The instance class used."
  type        = string
  default     = "cache.t3.small"
}

variable "cluster_mode_enabled" {
  type        = bool
  description = "If true, more than one instance is created. Cannot be true if single_instance_mode_enabled is true."
  default     = false
}

variable "single_instance_mode_enabled" {
  type        = bool
  description = "If true, it creates only one instance. Cannot be true if cluster_mode_enabled is true."
  default     = false
}

variable "multi_az_enabled" {
  description = "Specifies whether to enable Multi-AZ Support for the replication group. If true, `automatic_failover_enabled` must also be enabled."
  type        = bool
  default     = false
}

variable "automatic_failover_enabled" {
  description = "Specifies whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails. If true, Multi-AZ is enabled for this replication group. If false, Multi-AZ is disabled for this replication group. Must be enabled for Redis (cluster mode enabled) replication groups"
  type        = bool
  default     = false
}

variable "snapshot_retention_limit" {
  description = "Number of days for which ElastiCache will retain automatic cache cluster snapshots before deleting them"
  type        = number
  default     = 0
}

variable "snapshot_window" {
  description = "Daily time range (in UTC) during which ElastiCache will begin taking a daily snapshot of your cache cluster. Example: `05:00-09:00`"
  type        = string
  default     = null
}

variable "at_rest_encryption_enabled" {
  description = "Whether to enable encryption at rest"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "The ARN of the key that you wish to use if encrypting at rest. If not supplied, uses service managed encryption. Can be specified only if `at_rest_encryption_enabled = true`"
  type        = string
  default     = null
}

variable "auth_token" {
  description = "The password used to access a password protected server. Can be specified only if `transit_encryption_enabled = true`"
  type        = string
  default     = null
}

variable "transit_encryption_enabled" {
  description = "Enable encryption in-transit running in a VPC"
  type        = bool
  default     = true
}

variable "maintenance_window" {
  description = "Specifies the weekly time range for when maintenance on the cache cluster is performed. The format is `ddd:hh24:mi-ddd:hh24:mi` (24H Clock UTC)"
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "Whether any database modifications are applied immediately, or during the next maintenance window."
  type        = bool
  default     = true
}

variable "port" {
  description = "The port number on which each of the cache nodes will accept connections."
  type        = number
  default     = 6379
}

variable "parameters" {
  description = "List of ElastiCache parameters to apply"
  type        = list(map(string))
  default     = []
}

variable "num_node_groups" {
  description = "Number of node groups (shards) for this Redis replication group. Changing this number will trigger a resizing operation before other settings modifications"
  type        = number
  default     = 1
}

variable "replicas_per_node_group" {
  description = "Number of replica nodes in each node group. Changing this number will trigger a resizing operation before other settings modifications. Valid values are 0 to 5"
  type        = number
  default     = 0
}