locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Project     = var.project
  }

  # Additional AWS account numbers to add to the aws-auth configmap
  #
  map_accounts = [
    # var.accounts.security.id, # security
    # var.shared_account_id, # shared
    # var.appsdevstg_account_id, # apps-devstg
  ]

  # Additional IAM users to add to the aws-auth configmap. See examples/basic/variables.tf for example format
  #
  map_users = [
    # {
    #   userarn  = "arn:aws:iam:${var.accounts.security.id}:user/jane.doe"
    #   username = "jane.doe"
    #   groups   = ["system:masters"]
    # },
    # {
    #   userarn  = "arn:aws:iam:${var.accounts.security.id}:user/john.doe"
    #   username = "john.doe"
    #   groups   = ["system:masters"]
    # },
  ]

  # Additional IAM roles to add to the aws-auth configmap.
  #
  map_roles = [
    #
    # Github Actions Workflow will assume this role in order to be able to destroy the cluster
    #
    {
      rolearn  = "arn:aws:iam::${var.appsdevstg_account_id}:role/DeployMaster"
      username = "DeployMaster"
      groups = [
      "system:masters"]
    },
    #
    # Allow DevOps role to become cluster admins
    #
    {
      rolearn  = "arn:aws:iam::${var.appsdevstg_account_id}:role/DevOps"
      username = "DevOps"
      groups = [
      "system:masters"]
    },
  ]
}
