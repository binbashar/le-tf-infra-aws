#
# config/backend.config
#
#================================#
# Terraform AWS Backend Settings #
#================================#
variable "region" {
  type        = string
  description = "AWS Region"
}

variable "profile" {
  type        = string
  description = "AWS Profile (required by the backend but also used for other resources)"
}

variable "bucket" {
  type        = string
  description = "AWS S3 TF State Backend Bucket"
}

variable "dynamodb_table" {
  type        = string
  description = "AWS DynamoDB TF Lock state table name"
}

variable "encrypt" {
  type        = bool
  description = "Enable AWS DynamoDB with server side encryption"
}

#
# config/base.config
#
#=============================#
# Project Variables           #
#=============================#
variable "project" {
  type        = string
  description = "Project Name"
}

variable "project_long" {
  type        = string
  description = "Project Long Name"
}

variable "environment" {
  type        = string
  description = "Environment Name"
}

#
# config/extra.config
#
#=============================#
# Accounts & Extra Vars       #
#=============================#
variable "region_secondary" {
  type        = string
  description = "AWS Scondary Region for HA"
}

variable "security_account_id" {
  type        = string
  description = "Account: Security & Users Management"
}

variable "shared_account_id" {
  type        = string
  description = "Account: Shared Resources"
}

variable "appsdevstg_account_id" {
  type        = string
  description = "Account: Dev Modules & Libs"
}

variable "appsprd_account_id" {
  type        = string
  description = "Account: Prod Modules & Libs"
}

#===========================================#
# K8s EKS                                   #
#===========================================#
variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.14"
}

#
# Security: K8s EKS API via private endpoint
#
variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled."
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled."
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

variable "create_sg_eks_workers_customer" {
  description = "true if EKS cutomer managed workers mgmt sg needs to be created"
  type        = bool
  default     = false
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

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)

  default = [
    "900980591242", # security
    "763606934258", # shared
    "523857393444", # dev
  ]
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

  default = [
    {
      rolearn  = "arn:aws:iam::900980591242:role/DevOps"
      username = "DevOps"
      groups   = ["system:masters"]
    },
  ]
}
