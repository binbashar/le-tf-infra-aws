locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Project     = var.project
    Cluster     = data.terraform_remote_state.cluster.outputs.cluster_name
    Layer       = local.layer_name
  }
  addons_available = {
    coredns = {
      addon_version               = "v1.11.3-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    kube-proxy = {
      addon_version               = "v1.31.1-eksbuild.2"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    vpc-cni = {
      addon_version               = "v1.18.5-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      service_account_role_arn    = data.terraform_remote_state.cluster-identities.outputs.eks_addons_vpc_cni
    }
    aws-ebs-csi-driver = {
      addon_version               = "v1.36.0-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      service_account_role_arn    = data.terraform_remote_state.cluster-identities.outputs.eks_addons_ebs_csi
    }
  }
}
