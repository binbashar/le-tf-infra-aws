#===========================================#
# K8s EKS                                   #
#===========================================#
variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.23"
}

#
# Security: K8s EKS API via private endpoint
#
variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled."
  type        = bool
  default     = false
}

variable "create_cluster_security_group" {
  description = "Whether to create security group rules for the access to the Amazon EKS private API server endpoint."
  type        = bool
  default     = true
}

variable "cluster_log_retention_in_days" {
  description = "Number of days to retain log events. Default retention - 90 days."
  type        = number
  default     = 7
}

variable "manage_aws_auth" {
  description = "Whether to apply the aws-auth configmap file."
  default     = true
}

variable "create_aws_auth" {
  description = "Whether to create the aws-auth configmap."
  default     = false
}

# WARNING: make sure you read the note about add-ons in the "locals.tf" file
variable "use_managed_addons" {
  description = "Whether to use EKS managed add-ons."
  type        = bool
  default     = false
}
