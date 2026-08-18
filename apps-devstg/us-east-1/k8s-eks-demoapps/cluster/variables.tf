#===========================================#
# K8s EKS                                   #
#===========================================#
# EKS does not allow skipping minor versions — each bump is one hop, applied
# and verified before the next. Node AMIs follow this value automatically.
variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.34"
}
# Amazon Linux 2 is gone from EKS 1.33 onwards — AWS publishes no AL2 AMI for
# 1.33+, only AL2023 (verify with:
# `aws ssm get-parameter --name /aws/service/eks/optimized-ami/<ver>/amazon-linux-2/recommended/image_id`).
# Migrated to AL2023 while still on 1.31, deliberately ahead of the version
# bumps, so a substrate change and a version jump never land in the same apply.
#
# AL2023 requires Nitro-based instances (ENA + NVMe) — keep Xen generations
# such as t2 out of `instance_types` below or those nodes will never boot.
#
# Managed Nodes cannot specify custom AMIs, only use the ones allowed by EKS.
# Ref: https://docs.aws.amazon.com/eks/latest/userguide/eks-ami-deprecation-faqs.html
variable "ami_type" {
  description = "The AMI type to be used when creating nodes"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
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
