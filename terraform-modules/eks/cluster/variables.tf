variable "project" {
  description = "The project name"
  type        = string
}

variable "environment" {
  description = "The environment name"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
}

variable "profile" {
  description = "The AWS profile"
  type        = string
}

variable "cluster_name" {
  description = "Name to use for the EKS cluster."
  type        = string
}

variable "vpc_id" {
  description = "VPC id to use for the EKS cluster."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet ids to use for the EKS cluster."
  type        = list(string)
}

variable "shared_vpc_cidr_block" {
  description = "VPC CIDR to use for the EKS nodes inbound rule."
  type        = string
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([0-9]|[1-2][0-9]|3[0-2]))?$", var.shared_vpc_cidr_block))
    error_message = "Must be a valid IPv4 CIDR block address."
  }
}

variable "subnet_cidrs" {
  description = "Subnet CIDRs to use for the EKS nodes outbound rule."
  type        = list(string)
  validation {
    condition     = can([for s in var.subnet_cidrs : regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([0-9]|[1-2][0-9]|3[0-2]))?$", s)])
    error_message = "Must be a valid IPv4 CIDR block address."
  }
}

variable "aws_kms_key_arn" {
  description = "KMS Key to encrypt selected k8s resources (secrets)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z\\-\\_0-9\\/\\:]{1,96}$", var.aws_kms_key_arn))
    error_message = "KMS Key ARN must start with letter, only contain letters, numbers, dashes, slashes, colons or underscores and must be between 1 and 96 characters."
  }
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.28"
}

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
  default     = 60
}

variable "create_aws_auth" {
  description = "Whether to create the aws-auth configmap."
  default     = false
}

variable "manage_aws_auth" {
  description = "Whether to apply the aws-auth configmap file."
  default     = true
}

variable "ami_type" {
  description = "Default AMI type for nodes"
  type        = string
  default     = "AL2_x86_64"
}

variable "disk_size" {
  description = "Default disk size for nodes"
  type        = number
  default     = 50
}

variable "instance_types" {
  description = "Default instance types list for nodes"
  type        = list(string)
  default     = ["t2.medium"]
}

variable "map_accounts" {
  description = "Map of account to add to the cluster"
  type        = list
  default     = []
}

variable "map_users" {
  description = "Map of users to add to the cluster"
  type        = list
  default     = []
}

variable "map_roles" {
  description = "Map of roles to add to the cluster"
  type        = list(object({
      rolearn  = string
      username = string
      groups   = list(string)
  }))
  default     = []
}

variable "tags" {
  description = "Extra tags"
  type        = map(string)
  default     = {}
}

variable "node_group_min_size" {
  description = "Min size for node group"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Max size for node group"
  type        = number
  default     = 6
}

variable "node_group_desired_size" {
  description = "Desired size for node group"
  type        = number
  default     = 1
}

variable "node_group_instance_types" {
  description = "Instance types for node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_capacity_type" {
  description = "Capacity type for node group (e.g. SPOT)"
  type        = string
  default     = "SPOT"
}

variable "create_default_node_groups" {
  description = "Whether to create the default node groups (one per subnet)"
  type        = bool
  default     = true
}

variable "additional_node_groups" {
  description = "Additional node groups"
  type        = map
  default     = {}
}

variable "pod_cidr" {
  description = "The CIDR the cluster will use to assign IPs to pods"
  type        = string
  default     = "10.100.0.0/16"
}
