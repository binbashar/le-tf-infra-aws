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

# WARNING: make sure you read the note about add-ons in the "locals.tf" file
variable "use_managed_addons" {
  description = "Whether to use EKS managed add-ons."
  type        = bool
  default     = false
}

#===========================================#
# v21 defaults worth knowing about          #
#===========================================#
# terraform-aws-eks v21 changed three node-group defaults in ways that are
# invisible in the diff. None is overridden here -- this block exists so the
# next reader does not have to rediscover them.
#
#   * IMDS `http_put_response_hop_limit` is now 1 (was 2). A hop limit of 1
#     means pods can no longer reach the instance metadata service, only
#     processes on the host can. Workloads and controllers here authenticate via
#     IRSA and are unaffected by that -- the VPC CNI is the exception, and it
#     reads no metadata either; it uses the node instance role (see
#     `iam_role_attach_cni_policy` in `locals.tf`).
#
#     Authentication was never the risk, though. **Something that reads IMDS for
#     *data* is**, and one thing here did: the AWS Load Balancer Controller
#     discovers its VPC ID from instance metadata, and crash-looped until it was
#     passed `vpcId`/`region` explicitly (see `k8s-components`). Prefer that fix
#     -- tell the component what it needs -- over
#     `metadata_options.http_put_response_hop_limit = 2`, which reopens metadata
#     to every pod on the node group. If the hop limit must be raised, do it on
#     the affected group rather than globally.
#
#   * `use_latest_ami_release_version` is now true (was false). Node groups
#     resolve the newest AMI release for their `ami_type` at plan time, so an
#     apply that follows an AWS AMI release will roll the nodes. That is the
#     desired behaviour for a short-lived reference cluster; pin
#     `ami_release_version` per group if a stable substrate is ever needed.
#
#   * `enable_monitoring` is now false (was true). EC2 detailed (1-minute)
#     monitoring is off, which is what this cluster wants -- it costs money and
#     nothing here reads those metrics.
