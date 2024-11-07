module "cluster" {
  source = "github.com/binbashar/terraform-aws-eks.git?ref=v20.28.0"

  create          = true
  cluster_name    = data.terraform_remote_state.cluster-vpc.outputs.cluster_name
  cluster_version = var.cluster_version
  enable_irsa     = true

  enable_cluster_creator_admin_permissions = true

  # Configure networking
  vpc_id     = data.terraform_remote_state.cluster-vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.cluster-vpc.outputs.private_subnets

  # Configure public/private cluster endpoints
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  # Configure cluster inbound/outbound rules
  create_cluster_security_group = var.create_cluster_security_group
  cluster_security_group_additional_rules = {
    ingress_shared_vpc_443 = {
      description = "Shared VPC to Cluster API"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [
        data.terraform_remote_state.shared-vpc.outputs.vpc_cidr_block
      ]
    }
  }

  # Configure node inbound/outbound rules
  node_security_group_additional_rules = {
    #
    # NOTE: these 2 rules below allow all communication between nodes.
    # A more secure approach would only allow specific ports & protocols to
    # communicate between nodes. However, although said approach can be
    # achieved, it requires a deeper understanding of the architecture of
    # the components and workloads that you run in the cluster.
    #
    ingress_self_all = {
      description = "Node to Node all ports & protocols"
      protocol    = -1
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    },
    egress_self_all = {
      description = "Node to Node all ports & protocols"
      protocol    = -1
      from_port   = 0
      to_port     = 0
      type        = "egress"
      self        = true
    },
  }

  #
  # Specify the CIDR of k8s services -- Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster#kubernetes_network_config
  #
  # TODO Revisit this -- is it really needed?
  #
  cluster_service_ipv4_cidr = "10.100.0.0/16"

  # Encrypt selected k8s resources with this account's KMS CMK
  create_kms_key = false
  cluster_encryption_config = {
    provider_key_arn = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
    resources        = ["secrets"]
  }

  # Define Managed Nodes Groups (MNG's) default settings
  eks_managed_node_group_defaults = {
    # Managed Nodes cannot specify custom AMIs, only use the ones allowed by EKS
    ami_type       = "AL2_x86_64"
    disk_size      = 50
    instance_types = ["t2.medium"]
    k8s_labels     = local.tags
    # IMPORTANT: setting this to true is only necessary during the initial bootstrap
    # of the cluster, otherwise the built-in VPC CNI won't start. Then, after you get
    # the VPC CNI add-on installed, you can set this to false.
    iam_role_attach_cni_policy = true
  }

  # Define all Managed Node Groups (MNG's)
  eks_managed_node_groups = {
    # ---------------------------------------------------------------
    # Standard, On-demand, single node group across all AZs
    # ---------------------------------------------------------------
    # standard_ondemand = {
    #   min_size       = 1
    #   max_size       = 6
    #   desired_size   = 1
    #   capacity_type  = "ON_DEMAND"
    #   instance_types = ["t3.medium"]
    # }

    # ---------------------------------------------------------------
    # Standard, On-demand, one node group per AZs (HA)
    # ---------------------------------------------------------------
    # standard_ondemand_a = {
    #   min_size       = 1
    #   max_size       = 6
    #   desired_size   = 1
    #   capacity_type  = "ON_DEMAND"
    #   instance_types = ["t3.medium"]
    #   subnet_ids   = [data.terraform_remote_state.eks-vpc.outputs.private_subnets[0]]
    # }
    # standard_ondemand_b = {
    #   min_size       = 1
    #   max_size       = 6
    #   desired_size   = 1
    #   capacity_type  = "ON_DEMAND"
    #   instance_types = ["t3.medium"]
    #   subnet_ids   = [data.terraform_remote_state.eks-vpc.outputs.private_subnets[1]]
    # }

    # ---------------------------------------------------------------
    # Standard, Spot, single node group across all AZs
    # ---------------------------------------------------------------
    standard_spot = {
      desired_size   = 1
      max_size       = 6
      min_size       = 1
      capacity_type  = "SPOT"
      instance_types = ["t3.medium", "t3a.medium"]
      labels         = merge(local.tags, { "stack" = "standard" })
    }

    # ---------------------------------------------------------------
    # Tools, Spot, single node group across all AZs
    # ---------------------------------------------------------------
    # tools_spot = {
    #   desired_size   = 1
    #   max_size       = 6
    #   min_size       = 1
    #   capacity_type  = "SPOT"
    #   instance_types = ["t3.medium", "t3a.medium"]
    #   labels         = merge(local.tags, { "stack" = "tools" })
    #   taints         = {
    #     tools = {
    #       key    = "stack"
    #       value  = "tools"
    #       effect = "NO_SCHEDULE"
    #     }
    #   }
    # }
    # argocd = {
    #   desired_size   = 1
    #   max_size       = 2
    #   min_size       = 1
    #   capacity_type  = "SPOT"
    #   instance_types = ["t3.medium"]

    #   labels = merge(local.tags, { "stack" = "argocd" })
    #   taints = {
    #     dedicated_argocd = {
    #       key    = "stack"
    #       value  = "argocd"
    #       effect = "NO_SCHEDULE"
    #     }
    #   }
    # }
  }

  # Configure which roles, users and accounts can access the k8s api
  #create_aws_auth_configmap = var.create_aws_auth
  #manage_aws_auth_configmap = var.manage_aws_auth
  #aws_auth_roles            = local.map_roles
  #aws_auth_users            = local.map_users
  #aws_auth_accounts         = local.map_accounts

  # Configure which log types should be enabled and how long they should be kept for
  cluster_enabled_log_types = [
    # "api",
    # "audit",
    # "authenticator",
  ]
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_in_days

  # EKS Managed Add-ons
  cluster_addons = local.addons_enabled

  # Define tags (notice we are appending here tags required by the cluster autoscaler)
  tags = merge(local.tags,
    { "k8s.io/cluster-autoscaler/enabled" = "TRUE" },
    { "k8s.io/cluster-autoscaler/${data.terraform_remote_state.cluster-vpc.outputs.cluster_name}" = "owned" }
  )
}

# module "cluster-aws-auth" {
#   source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
#   version = "~> 20.0"

#   manage_aws_auth_configmap = var.manage_aws_auth
#   create_aws_auth_configmap = var.create_aws_auth

#   aws_auth_roles    = local.map_roles
#   aws_auth_users    = local.map_users
#   aws_auth_accounts = local.map_accounts

#   depends_on = [module.cluster]
# }
