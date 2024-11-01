locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Project     = var.project
  }

  #
  # Configure which IAM roles can have access to K8S API
  #
  map_roles = [
    #
    # Allow DevOps role to become cluster admins
    #
    {
      rolearn  = "arn:aws:iam::${var.accounts.apps-devstg.id}:role/DevOps"
      username = "DevOps"
      groups   = ["system:masters"]
    },
    #
    # Allow DevOps (SSO) role to become cluster admins
    #
    {
      rolearn  = "arn:aws:iam::${var.accounts.apps-devstg.id}:role/AWSReservedSSO_DevOps_2b78d1d8a7818ab3"
      username = "DevOps"
      groups   = ["system:masters"]
    },
    #
    # Allow Developer role access for specific Namespaces (Role/RoleBinding)
    #
    {
      rolearn  = "arn:aws:iam::${var.accounts.apps-devstg.id}:role/Developer"
      username = "Developer"
      groups   = ["system:authenticated"]
    },
  ]

  # To change the default node group use these vars:
  #
  # node_group_min_size
  # node_group_max_size
  # node_group_desired_size
  # node_group_instance_types
  # node_group_capacity_type
  #
  # For additional node groups complete the following object like this one:
  #
  #additional_node_groups = {
  #  monitoring = {
  #    min_size       = 1,
  #    max_size       = 3,
  #    desired_size   = 1,
  #    instance_types = ["t3a.medium"],
  #    subnet_ids = data.terraform_remote_state.eks-vpc.outputs.private_subnets
  #    labels     = merge(local.tags, { "stack" = "monitoring" })
  #    taints = {
  #      dedicated_monitoring = {
  #        key    = "stack"
  #        value  = "monitoring"
  #        effect = "NO_SCHEDULE"
  #      }
  #    }
  #  }
  #}
  additional_node_groups = {
  }
}
