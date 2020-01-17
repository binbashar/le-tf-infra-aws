#===========================================#
# AWS Provider Settings                     #
#===========================================#
variable "region" {
  description = "AWS Region"
}

variable "profile" {
  description = "AWS Profile"
}

#===========================================#
# Project Variables                         #
#===========================================#
variable "project" {
  description = "Project Name"
}

variable "environment" {
  description = "Environment Name"
}

variable "security_account_id" {}
variable "shared_account_id" {}
variable "dev_account_id" {}
variable "bucket" {}

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
variable "cluster_create_security_group" {
  description = "Whether to create a security group for the cluster or attach the cluster to `cluster_security_group_id`."
  type        = bool
  default     = true
}

variable "worker_create_security_group" {
  description = "Whether to create a security group for the workers or attach the workers to `worker_security_group_id`."
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

variable "local_exec_interpreter" {
  description = "Command to run for local-exec resources. Must be a shell-style interpreter. If you are on Windows Git Bash is a good choice."
  type        = list(string)
  default     = ["/bin/zsh", "-c"]
}


#
# aws-iam-authenticator variables
#
variable "manage_aws_auth" {
  description = "Whether to apply the aws-auth configmap file."
  default     = true
}

variable "write_aws_auth_config" {
  description = "Whether to write the aws-auth configmap file."
  type        = bool
  default     = true
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

variable "kubeconfig_aws_authenticator_command" {
  description = "Command to use to fetch AWS EKS credentials."
  type        = string
  default     = "aws-iam-authenticator"
}

variable "kubeconfig_aws_authenticator_command_args" {
  description = "Default arguments passed to the authenticator command. Defaults to [token -i $cluster_name]."
  type        = list(string)
  default     = []
}

variable "kubeconfig_aws_authenticator_additional_args" {
  description = "Any additional arguments to pass to the authenticator such as the role to assume. e.g. [\"-r\", \"MyEksRole\"]."
  type        = list(string)
  default     = []
}

variable "kubeconfig_aws_authenticator_env_variables" {
  description = "Environment variables that should be used when executing the authenticator. e.g. { AWS_PROFILE = \"eks\"}."
  type        = map(string)
  default     = {}
}