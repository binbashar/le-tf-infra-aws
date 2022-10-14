module "cluster" {
  source = "github.com/binbashar/terraform-aws-eks.git?ref=v18.30.0"

  create          = true
  cluster_name    = data.terraform_remote_state.cluster-vpc.outputs.cluster_name
  cluster_version = var.cluster_version
  enable_irsa     = true

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
    #
    # Admission controller rules
    #
    ingress_nginx_ingress_admission_controller_webhook_tcp = {
      description                   = "Cluster API to Nginx Ingress Admission Controller Webhook"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    },
    ingress_alb_ingress_admission_controller_webhook_tcp = {
      description                   = "Cluster API to ALB Ingress Admission Controller Webhook"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      type                          = "ingress"
      source_cluster_security_group = true
    },
    #
    # DNS communication with the Internet
    #
    # TODO We may want to harden this either by restricting this rule or
    #      via centralized outbound traffic control (e.g. a Firewall appliance,
    #      Route 53 DNS Resolver Firewall)
    #
    egress_public_dns_tcp = {
      description = "Node to public DNS servers"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    },
    egress_public_dns_udp = {
      description = "Node to public DNS servers"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    },
    #
    # Access to resources in EKS VPC
    #
    egress_eks_private_subnets_tcp = {
      description = "Node to EKS Private Subnets"
      protocol    = "tcp"
      from_port   = 1024
      to_port     = 65535
      type        = "egress"
      cidr_blocks = [data.terraform_remote_state.cluster-vpc.outputs.private_subnets_cidr[0]]
    },
    #
    # Access to resources in Shared VPC
    #
    # TODO This is another outbound rule that could be tightened
    #
    egress_shared_vpc_all = {
      description = "Node to HTTPS endpoints on Shared VPC"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "egress"
      cidr_blocks = [data.terraform_remote_state.shared-vpc.outputs.vpc_cidr_block]
    },
    #
    # Github SSH (for ArgoCD to access repos via SSH
    #
    # TODO Have ArgoCD connect to Github via HTTPS
    #
    egress_github_ssh_tcp = {
      description = "Node to Github SSH"
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    },
  }

  #
  # Specify the CIDR of k8s services -- Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster#kubernetes_network_config
  #
  # TODO Revisit this -- is it really needed?
  #
  cluster_service_ipv4_cidr = "10.100.0.0/16"

  # Encrypt selected k8s resources with this account's KMS CMK
  cluster_encryption_config = [{
    provider_key_arn = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
    resources        = ["secrets"]
  }]

  # Define Managed Nodes Groups (MNG's) default settings
  eks_managed_node_group_defaults = {
    # Managed Nodes cannot specify custom AMIs, only use the ones allowed by EKS
    ami_type       = "AL2_x86_64"
    disk_size      = 50
    instance_types = ["t2.medium"]
    k8s_labels     = local.tags
  }

  # Define all Managed Node Groups (MNG's)
  eks_managed_node_groups = {
    # on-demand = {
    #   min_size       = 1
    #   max_size       = 6
    #   desired_size   = 1
    #   capacity_type  = "ON_DEMAND"
    #   instance_types = ["t2.medium", "t3.medium"]
    # }
    spot = {
      desired_capacity = 1
      max_capacity     = 6
      min_capacity     = 1
      capacity_type    = "SPOT"
      instance_types   = ["t2.medium", "t3.medium"]
    }
  }

  # Configure which roles, users and accounts can access the k8s api
  manage_aws_auth_configmap = var.manage_aws_auth
  aws_auth_roles            = local.map_roles
  aws_auth_users            = local.map_users
  aws_auth_accounts         = local.map_accounts

  # Configure which log types should be enabled and how long they should be kept for
  cluster_enabled_log_types = [
    # "api",
    # "audit",
    # "authenticator",
  ]
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_in_days

  # Define tags (notice we are appending here tags required by the cluster autoscaler)
  tags = merge(local.tags,
    { "k8s.io/cluster-autoscaler/enabled" = "TRUE" },
    { "k8s.io/cluster-autoscaler/${data.terraform_remote_state.cluster-vpc.outputs.cluster_name}" = "owned" }
  )
}
