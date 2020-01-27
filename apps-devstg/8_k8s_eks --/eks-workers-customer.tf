//module "eks" {
//  source          = "git::git@github.com:binbashar/terraform-aws-eks.git?ref=v8.1.0"
//
//  create_eks      = false
//  cluster_name    = data.terraform_remote_state.vpc-eks.outputs.cluster_name
//  cluster_version = var.cluster_version
//
//  #
//  # Network configurations
//  #
//  vpc_id          = data.terraform_remote_state.vpc-eks.outputs.vpc_id
//  subnets         = data.terraform_remote_state.vpc-eks.outputs.private_subnets[0]
//
//  #
//  # Security
//  #
//  worker_additional_security_group_ids         = [aws_security_group.all_worker_mgmt[0].id]
//  cluster_endpoint_private_access              = var.cluster_endpoint_private_access
//  cluster_endpoint_public_access               = var.cluster_endpoint_public_access
//
//  #
//  # AWS EKS Customer Managed Worker Nodes
//  #
//  worker_groups = [
//    {
//      name                          = "worker-group-1"
//      instance_type                 = "t3.small"
//      additional_userdata           = "echo foo bar"
//      bootstrap_extra_args          = "--enable-docker-bridge true" # You are running Continuous Integration in K8s,
//                                                                    # and building docker images by either mounting the
//                                                                    # docker sock as a volume or using docker in docker
//      asg_desired_capacity          = 1
//      asg_max_size                  = 3
//      additional_security_group_ids = [aws_security_group.all_worker_mgmt[0].id]
//      public_ip                     = false
//    },
//    {
//      name                          = "worker-group-2"
//      instance_type                 = "t3.medium"
//      additional_userdata           = "echo foo bar"
//      bootstrap_extra_args          = "--enable-docker-bridge true"
//      asg_desired_capacity          = 1
//      asg_max_size                  = 3
//      additional_security_group_ids = [aws_security_group.all_worker_mgmt[0].id]
//      public_ip                     = false
//    },
//  ]
//
//  #
//  # Auth: Kubeconfig
//  #
//  kubeconfig_name                  = var.kubeconfig_name
//  write_kubeconfig                 = var.write_kubeconfig
//  config_output_path               = var.config_output_path
//  local_exec_interpreter           = var.local_exec_interpreter
//
//  #
//  # Auth: aws-iam-authenticator
//  #
//  manage_aws_auth                  = var.manage_aws_auth
//  map_roles                        = var.map_roles
//  map_accounts                     = var.map_accounts
//
//  #
//  # Tags
//  #
//  tags                             = local.tags
//}
