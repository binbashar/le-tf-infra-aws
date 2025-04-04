locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Project     = var.project
    #Layer       = local.layer_name
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
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::${var.accounts.apps-devstg.id}:role/AWSReservedSSO_DevOps_2b78d1d8a7818ab3"
      username = "DevOps"
      groups   = ["system:masters"]
    },
  ]

  # ---------------------------------------------------------------------------
  # IMPORTANT
  # ---------------------------------------------------------------------------
  # If you plan to use EKS managed add-ons keep in mind that some add-ons rely
  # on IAM roles which need to be created/updated for them to work. Said roles
  # are defined in the "identities" layer which needs to be applied only after
  # the cluster is up and running. You can orchestrate that execution in that
  # order by toggling the "use_managed_addons" variable in "variables.tf".
  # Said execution order should go as follows:
  #   1. Apply this layer
  #   2. Apply the identities layers
  #   3. Enable the "use_managed_addons" variable and apply this layer again
  # ---------------------------------------------------------------------------
  addons_available = {
  }
  addons_enabled = var.use_managed_addons ? local.addons_available : {}
}
