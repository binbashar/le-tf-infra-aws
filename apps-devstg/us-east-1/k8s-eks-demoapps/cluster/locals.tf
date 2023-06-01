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
  # the cluster is up and running. After that you should be able to install the
  # managed add-ons on the cluster.
  # ---------------------------------------------------------------------------
  addons_available = {
    coredns = {
      addon_version     = "v1.8.7-eksbuild.4"
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      addon_version     = "v1.22.17-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      addon_version            = "v1.12.6-eksbuild.2"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = data.terraform_remote_state.cluster-identities.outputs.eks_addons_vpc_cni
    }
    aws-ebs-csi-driver = {
      addon_version            = "v1.18.0-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = data.terraform_remote_state.cluster-identities.outputs.eks_addons_ebs_csi
    }
  }
  addons_enabled = var.use_managed_addons ? local.addons_available : {}
}
