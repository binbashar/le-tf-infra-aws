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
    # var.accounts.shared.id, # shared
    # var.accounts.apps-devstg.id, # apps-devstg
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
      rolearn  = "arn:aws:iam::${var.accounts.apps-devstg.id}:role/DeployMaster"
      username = "DeployMaster"
      groups = [
      "system:masters"]
    },
    #
    # Allow DevOps role to become cluster admins
    #
    {
      rolearn  = "arn:aws:iam::${var.accounts.apps-devstg.id}:role/DevOps"
      username = "DevOps"
      groups = [
      "system:masters"]
    },
    #
    # Allow DevOps SSO role to become cluster admins
    #
    {
      rolearn  = "arn:aws:iam::${var.accounts.apps-devstg.id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_DevOps_5e0501636a32f9c4"
      username = "DevOps"
      groups = [
      "system:masters"]
    },
  ]
}
