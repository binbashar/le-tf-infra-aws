variable "cluster_size" {
  type        = number
  description = "Number of nodes in cluster"
  default     = 1
}

variable "instance_type" {
  type        = string
  description = "Elastic cache instance type"
  default     = "cache.t3.small"
}

variable "port" {
  description = "The port number on which each of the cache nodes will accept connections."
  type        = number
  default     = 6379
}

variable "family" {
  type        = string
  description = "Redis family"
  default     = "redis7"
}

variable "engine_version" {
  type        = string
  description = "Redis engine version"
  default     = "7.1"
}

variable "at_rest_encryption_enabled" {
  type        = bool
  description = "Enable encryption at rest"
  default     = true
}

variable "transit_encryption_enabled" {
  type        = bool
  description = "Enable TLS"
  default     = true
}
