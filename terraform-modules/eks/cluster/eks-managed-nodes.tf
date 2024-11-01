module "cluster" {
  # updated to v19.21.0 because v20 does not handle aws_auth, it has to be
  # managed on its own
  source = "github.com/binbashar/terraform-aws-eks.git?ref=v19.21.0"

  create          = true
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  enable_irsa     = true

  # Configure networking
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

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
        var.shared_vpc_cidr_block
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
    #ingress_nginx_ingress_admission_controller_webhook_tcp = {
    #  description                   = "Cluster API to Nginx Ingress Adminission Controller Webhook"
    #  protocol                      = "tcp"
    #  from_port                     = 8443
    #  to_port                       = 8443
    #  type                          = "ingress"
    #  source_cluster_security_group = true
    #},
    #ingress_alb_ingress_admission_controller_webhook_tcp = {
    #  description                   = "Cluster API to ALB Ingress Adminission Controller Webhook"
    #  protocol                      = "tcp"
    #  from_port                     = 9443
    #  to_port                       = 9443
    #  type                          = "ingress"
    #  source_cluster_security_group = true
    #},
    ingress_alb_ingress_metrics_tcp = {
      description                   = "Cluster API to ALB Ingress Metrics"
      protocol                      = "tcp"
      from_port                     = 8080
      to_port                       = 8080
      type                          = "ingress"
      source_cluster_security_group = true
    },
    ingress_certmanager_metrics_tcp = {
      description                   = "Cluster API to CertManager Metrics"
      protocol                      = "tcp"
      from_port                     = 9402
      to_port                       = 9402
      type                          = "ingress"
      source_cluster_security_group = true
    },
    ingress_alb_ingress_metrics_tcp = {
      description                   = "Cluster API to ALB Ingress Metrics"
      protocol                      = "tcp"
      from_port                     = 8080
      to_port                       = 8080
      type                          = "ingress"
      source_cluster_security_group = true
    },
    ingress_redis_ha_metrics_tcp = {
      description                   = "Cluster API to ArgoCD Redis HA Metrics"
      protocol                      = "tcp"
      from_port                     = 9121
      to_port                       = 9121
      type                          = "ingress"
      source_cluster_security_group = true
    },
    #
    # DNS communication with the Internet
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
    # Github SSH (for ArgoCD to access repos via SSH -- until we can securely do that via HTTPS)
    #
    egress_github_ssh_tcp = {
      description = "Node to Github SSH"
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    },
    #
    # This was needed because both DroneCI and APT-Repo needed to access external Aptitude
    # repositories (e.g. archive.ubuntu.com, security.ubuntu.com, packages.ros.org). These
    # repositories don't seem to publish the public CIDRs they use and also there is no
    # indication on whether they are static, thus there's no guarantee we won't need to
    # update this down the road.
    # TODO We may consider implementing a better outbound traffic control so we can more
    #      tightly and convenient control which connections are allowed to go out and to
    #      to which hosts.
    # TODO It was also discussed the possibility of moving DroneCI and APT-Repo to a
    #      tooling cluster, separate from the workloads cluster, but that may also present
    #      the same challenges we are trying to solve here.
    #
    egress_ubuntu_http_tcp = {
      description = "Node to HTTP"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      type        = "egress"
      cidr_blocks = [
        "91.189.91.39/32",    # archive.ubuntu.com, security.ubuntu.com
        "91.189.91.38/32",    # archive.ubuntu.com, security.ubuntu.com
        "185.125.190.36/32",  # archive.ubuntu.com, security.ubuntu.com
        "185.125.190.39/32",  # archive.ubuntu.com, security.ubuntu.com
        "140.211.166.134/32", # packages.ros.org
        "64.50.236.52/32",    # packages.ros.org
        "64.50.233.100/32",   # packages.ros.org
        "146.75.0.0/16",      # debian.map.fastlydns.net
        "199.232.0.0/16"      # deb.debian.org
      ]
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
      cidr_blocks = var.subnet_cidrs
    },
    #
    # Access to resources in Shared VPC
    #
    egress_shared_vpc_all = {
      description = "Node to HTTPS endpoints on Shared VPC"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "egress"
      cidr_blocks = [var.shared_vpc_cidr_block]
    },
  }

  # Specify the CIDR of k8s services -- Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster#kubernetes_network_config
  cluster_service_ipv4_cidr = var.pod_cidr

  # Encrypt selected k8s resources with this account's KMS CMK
  cluster_encryption_config = {
    provider_key_arn = var.aws_kms_key_arn
    resources        = ["secrets"]
  }

  # Enable default policy on kms key
  kms_key_enable_default_policy = true

  # Define Managed Nodes Groups (MNG's) default settings
  eks_managed_node_group_defaults = {
    # Managed Nodes cannot specify custom AMIs, only use the ones allowed by EKS
    ami_type                      = var.ami_type
    disk_size                     = var.disk_size
    instance_types                = var.instance_types
    k8s_labels                    = var.tags
    iam_role_additional_policies  = {
      "ecr" = module.iam_policy_ecr_pullthrough_cache.arn
    }
  }

  # Define all Managed Node Groups (MNG's)
  eks_managed_node_groups = local.node_groups

  # Configure which roles, users and accounts can access the k8s api
  create_aws_auth_configmap = var.create_aws_auth
  manage_aws_auth_configmap = var.manage_aws_auth
  aws_auth_roles            = var.map_roles
  aws_auth_users            = var.map_users
  aws_auth_accounts         = var.map_accounts

  # Configure which log types should be enabled and how long they should be kept for
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
  ]
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_in_days

  # Define tags (notice we are appending here tags required by the cluster autoscaler)
  tags = merge(var.tags,
    { "k8s.io/cluster-autoscaler/enabled" = "TRUE" },
    { "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned" }
  )
}

module "iam_policy_ecr_pullthrough_cache" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-policy?ref=v4.24.1"

  create_policy = true
  name          = "${var.project}-${var.environment}-ecr-pullthrough-cache"
  description   = "Used for ECR PullThrough Cache"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRCachePolicy",
      "Effect": "Allow",
      "Action": [
        "ecr:CreateRepository",
        "ecr:BatchImportUpstreamImage",
        "ecr:PutImage",
        "ecr:PutLifecyclePolicy",
        "ecr:SetRepositoryPolicy",
        "ecr:TagResource"
      ],
      "Resource": [
        "arn:aws:ecr:${var.region}:284136477206:repository/docker-hub/*"
      ]
    }
  ]
}
EOF

  tags = var.tags
}
