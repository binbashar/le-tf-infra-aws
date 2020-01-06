module "eks" {
  source          = "git::git@github.com:binbashar/terraform-aws-eks.git?ref=v7.0.0"
  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  #
  # Network configurations
  #
  vpc_id = module.vpc-eks.vpc_id
  subnets         = module.vpc-eks.private_subnets

  #
  # Security
  #
  cluster_create_security_group                = var.cluster_create_security_group
  worker_create_security_group                 = var.worker_create_security_group
  worker_additional_security_group_ids         = [aws_security_group.all_worker_mgmt.id]
  cluster_endpoint_private_access              = var.cluster_endpoint_private_access
  cluster_endpoint_public_access               = var.cluster_endpoint_public_access

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t3.small"
      additional_userdata           = "echo foo bar"
      bootstrap_extra_args          = "--enable-docker-bridge true" # You are running Continuous Integration in K8s,
                                                                    # and building docker images by either mounting the
                                                                    # docker sock as a volume or using docker in docker
      asg_desired_capacity          = 1
      asg_max_size                  = 3
      additional_security_group_ids = [aws_security_group.all_worker_mgmt.id]
      public_ip                     = false
    },
    {
      name                          = "worker-group-2"
      instance_type                 = "t3.medium"
      additional_userdata           = "echo foo bar"
      bootstrap_extra_args          = "--enable-docker-bridge true"
      asg_desired_capacity          = 1
      asg_max_size                  = 3
      additional_security_group_ids = [aws_security_group.all_worker_mgmt.id]
      public_ip                     = false
    },
  ]

  #
  # Auth: Kubeconfig
  #
  kubeconfig_name                              = var.kubeconfig_name
  write_kubeconfig                             = var.write_kubeconfig
  config_output_path                           = var.config_output_path
  local_exec_interpreter                       = var.local_exec_interpreter

  #
  # Auth: aws-iam-authenticator
  #
  manage_aws_auth                              = var.manage_aws_auth
  write_aws_auth_config                        = var.write_aws_auth_config
  map_roles                                    = var.map_roles
  kubeconfig_aws_authenticator_command_args    = var.kubeconfig_aws_authenticator_command_args
  kubeconfig_aws_authenticator_additional_args = var.kubeconfig_aws_authenticator_additional_args
  kubeconfig_aws_authenticator_env_variables   = var.kubeconfig_aws_authenticator_env_variables

  #
  # Tags
  #
  tags                                         = local.tags

}