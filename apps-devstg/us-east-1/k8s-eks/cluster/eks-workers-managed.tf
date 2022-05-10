module "eks" {
  source = "github.com/binbashar/terraform-aws-eks.git?ref=v17.24.0"

  create_eks      = true
  cluster_name    = data.terraform_remote_state.eks-vpc.outputs.cluster_name
  cluster_version = var.cluster_version
  enable_irsa     = true

  #
  # Network configurations
  #
  vpc_id  = data.terraform_remote_state.eks-vpc.outputs.vpc_id
  subnets = data.terraform_remote_state.eks-vpc.outputs.private_subnets

  #
  # Security: public vs private access (and private access rules)
  #
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  cluster_create_endpoint_private_access_sg_rule = var.cluster_create_endpoint_private_access_sg_rule
  cluster_endpoint_private_access_cidrs = [
    data.terraform_remote_state.shared-vpc.outputs.vpc_cidr_block,
    "172.25.16.0/20" # HCP Vault HVN
  ]

  #
  # Important: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster#kubernetes_network_config
  #
  cluster_service_ipv4_cidr = "10.100.0.0/16"

  #
  # Managed Nodes Default Settings
  #
  node_groups_defaults = {
    # Managed Nodes cannot specify custom AMIs, only use the ones allowed by EKS
    ami_type       = "AL2_x86_64"
    disk_size      = 50
    instance_types = ["t2.medium", "t3.medium"]
    k8s_labels     = local.tags
  }

  #
  # List of Managed Node Groups
  #
  node_groups = {
    main = {
      desired_capacity = var.node_groups_desired_capacity
      max_capacity     = var.node_groups_max_capacity
      min_capacity     = var.node_groups_min_capacity
      capacity_type    = var.node_groups_capacity_type
    }
  }

  #
  # Auth: Kubeconfig
  #
  kubeconfig_name                              = var.kubeconfig_name
  write_kubeconfig                             = var.write_kubeconfig
  kubeconfig_output_path                       = var.config_output_path
  kubeconfig_aws_authenticator_additional_args = ["--cache"]
  kubeconfig_aws_authenticator_env_variables = {
    AWS_PROFILE = var.profile,
    #
    # IMPORTANT: once the cluster is created you will need to replace $HOME
    #   with the path to your home directory because replacing environment
    #   variables is not support by kubeconfig clients yet.
    #
    AWS_CONFIG_FILE             = "$HOME/.aws/${var.project}/config",
    AWS_SHARED_CREDENTIALS_FILE = "$HOME/.aws/${var.project}/credentials"
  }

  #
  # Auth: aws-iam-authenticator
  #
  manage_aws_auth = var.manage_aws_auth
  map_roles       = local.map_roles
  map_accounts    = local.map_accounts
  map_users       = local.map_users

  #
  # Logging: which log types should be enabled and how long they should be kept for
  #
  cluster_enabled_log_types = [
    # "api",
    # "audit",
    # "authenticator",
    # "controllerManager",
    # "scheduler"
  ]
  cluster_log_retention_in_days = 7

  #
  # Tags
  #
  tags = merge(local.tags,
    { "k8s.io/cluster-autoscaler/enabled" = "TRUE" },
    { "k8s.io/cluster-autoscaler/${data.terraform_remote_state.eks-vpc.outputs.cluster_name}" = "owned" }
  )
}
