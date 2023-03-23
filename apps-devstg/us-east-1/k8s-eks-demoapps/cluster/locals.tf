locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Project     = var.project
  }

  # Additional AWS account numbers to add to the aws-auth configmap
  map_accounts = []

  # Additional IAM users to add to the aws-auth configmap. See examples/basic/variables.tf for example format
  map_users = []

  # Additional IAM roles to add to the aws-auth configmap.
  map_roles = [
    #
    # Allow DevOps role to become cluster admins
    #
    {
      rolearn  = "arn:aws:iam::${var.accounts.apps-devstg.id}:role/DevOps"
      username = "DevOps"
      groups = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::${var.accounts.apps-devstg.id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_DevOps_2b78d1d8a7818ab3"
      username = "DevOps"
      groups = ["system:masters"]
    },

  ]
}
