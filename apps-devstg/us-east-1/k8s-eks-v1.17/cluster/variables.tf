#===========================================#
# K8s EKS Variables                         #
#===========================================#
variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.19"
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

#
# Security: Private Access Rules
#
variable "cluster_create_endpoint_private_access_sg_rule" {
  description = "Whether to create security group rules for the access to the Amazon EKS private API server endpoint."
  type        = bool
  default     = true
}

#
# Security: EKS Cluster & Workers Security Groups
#
variable "cluster_log_retention_in_days" {
  description = "Number of days to retain log events. Default retention - 90 days."
  type        = number
  default     = 60
}

#
# AutoScaling: EKS
#
variable "manage_worker_autoscaling_policy" {
  description = "Whether to attach the module managed cluster autoscaling iam policy to the default worker IAM role. This"
  type        = bool
  default     = true
}

#
# K8s Kubeconfig variables
#
variable "write_kubeconfig" {
  description = "Whether to write a Kubectl config file containing the cluster configuration. Saved to `config_output_path`."
  type        = bool
  default     = true
}

variable "config_output_path" {
  description = "Where to save the Kubectl config file (if `write_kubeconfig = true`). Assumed to be a directory if the value ends with a forward slash `/`."
  type        = string
  default     = "./"
}

variable "kubeconfig_name" {
  description = "Override the default name used for items kubeconfig."
  type        = string
  default     = ""
}

#
# aws-iam-authenticator variables
#
variable "manage_aws_auth" {
  description = "Whether to apply the aws-auth configmap file."
  default     = true
}
