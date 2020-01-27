module "eks" {
  source = "git::git@github.com:binbashar/terraform-aws-eks.git?ref=v8.1.0"

  create_eks      = true
  cluster_name    = data.terraform_remote_state.vpc-eks.outputs.cluster_name
  cluster_version = var.cluster_version

  #
  # Network configurations
  #
  vpc_id  = data.terraform_remote_state.vpc-eks.outputs.vpc_id
  subnets = data.terraform_remote_state.vpc-eks.outputs.private_subnets[0]

  #
  # Security
  #
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  #
  # AWS EKS Managed Worker Nodes
  #
  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

  node_groups = {
    example = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "t2.small"
      k8s_labels    = local.tags
      additional_tags = {
        ExtraTag = "example"
      }
    }
  }

  #
  # Auth: Kubeconfig
  #
  kubeconfig_name        = var.kubeconfig_name
  write_kubeconfig       = var.write_kubeconfig
  config_output_path     = var.config_output_path
  local_exec_interpreter = var.local_exec_interpreter

  #
  # Auth: aws-iam-authenticator
  #
  manage_aws_auth = var.manage_aws_auth
  map_roles       = var.map_roles
  map_accounts    = var.map_accounts

  #
  # Tags
  #
  tags = local.tags
}
