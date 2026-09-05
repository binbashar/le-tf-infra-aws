module "cluster" {
  source = "github.com/binbashar/terraform-aws-eks.git?ref=v21.25.0"

  create             = true
  name               = data.terraform_remote_state.cluster-vpc.outputs.cluster_name
  kubernetes_version = var.cluster_version
  enable_irsa        = true

  # Configure which roles can access the k8s API.
  #
  # Access entries replace the `aws-auth` ConfigMap, whose submodule was removed
  # in v21. See `locals.tf` for the entries themselves and for why the cluster
  # creator bootstrap is deliberately off rather than on.
  enable_cluster_creator_admin_permissions = false
  access_entries                           = local.access_entries

  # Widened from the module default of 30s.
  #
  # This is the *only* thing holding the node groups back until the VPC CNI
  # exists, and it is a timer rather than an edge: the module hands the node
  # groups `cluster_name = time_sleep.this[0].triggers["name"]`, and that
  # `time_sleep` triggers on the cluster's own attributes -- it never references
  # `aws_eks_addon.before_compute`, and `node_groups.tf` carries no `depends_on`.
  # So two branches race from the cluster, and the add-on branch has to finish
  # first or the nodes come up with no CNI and sit `NotReady` (the v20 -> v21
  # defect this layer exists to avoid).
  #
  # 30s was sized for `cluster -> CreateAddon`. This layer's add-on branch is
  # longer than that: `tls_certificate` -> OIDC provider -> the IRSA role in
  # `irsa-vpc-cni.tf` -> the add-on, three extra round trips including an IAM
  # create. Widening the gap does not make the race impossible -- only a real
  # edge would, and the module does not expose one -- but it restores the margin
  # the default assumed. Do NOT shorten this to speed up a spin.
  dataplane_wait_duration = "60s"

  # Configure networking
  vpc_id     = data.terraform_remote_state.cluster-vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.cluster-vpc.outputs.private_subnets

  # Configure public/private cluster endpoints
  endpoint_private_access = var.cluster_endpoint_private_access
  endpoint_public_access  = var.cluster_endpoint_public_access

  # Configure cluster inbound/outbound rules
  create_security_group = var.create_cluster_security_group
  security_group_additional_rules = {
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
  #
  # NOTE: `node_security_group_enable_recommended_rules` is left at its `true`
  # default, so the module already installs the control-plane -> node webhook
  # rules (4443, 6443, 8443, 9443), node-to-node ephemeral ingress and
  # egress_all. Only the rules below are additional.
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
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    },
    egress_self_all = {
      description = "Node to Node all ports & protocols"
      protocol    = "-1"
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
  service_ipv4_cidr = "10.100.0.0/16"

  # Encrypt selected k8s resources with this account's KMS CMK
  create_kms_key = false
  encryption_config = {
    provider_key_arn = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
    resources        = ["secrets"]
  }

  # Define all Managed Node Groups (MNG's)
  #
  # NOTE: v21 removed `eks_managed_node_group_defaults`, so the shared
  # attributes come from `local.node_group_defaults` via `merge()` -- see the
  # comment on that local. Keys set here override the shared value.
  eks_managed_node_groups = {
    # ---------------------------------------------------------------
    # Standard, On-demand, single node group across all AZs
    # ---------------------------------------------------------------
    # standard_ondemand = merge(local.node_group_defaults, {
    #   min_size       = 1
    #   max_size       = 6
    #   desired_size   = 1
    #   capacity_type  = "ON_DEMAND"
    #   instance_types = ["t3.medium"]
    # })

    # ---------------------------------------------------------------
    # Standard, On-demand, one node group per AZs (HA)
    # ---------------------------------------------------------------
    # standard_ondemand_a = merge(local.node_group_defaults, {
    #   min_size       = 1
    #   max_size       = 6
    #   desired_size   = 1
    #   capacity_type  = "ON_DEMAND"
    #   instance_types = ["t3.medium"]
    #   subnet_ids     = [data.terraform_remote_state.cluster-vpc.outputs.private_subnets[0]]
    # })
    # standard_ondemand_b = merge(local.node_group_defaults, {
    #   min_size       = 1
    #   max_size       = 6
    #   desired_size   = 1
    #   capacity_type  = "ON_DEMAND"
    #   instance_types = ["t3.medium"]
    #   subnet_ids     = [data.terraform_remote_state.cluster-vpc.outputs.private_subnets[1]]
    # })

    # ---------------------------------------------------------------
    # Standard, Spot, single node group across all AZs
    # ---------------------------------------------------------------
    standard_spot = merge(local.node_group_defaults, {
      desired_size  = 2
      max_size      = 6
      min_size      = 2
      capacity_type = "SPOT"
      labels        = merge(local.tags, { "stack" = "standard" })
    })

    # ---------------------------------------------------------------
    # Tools, Spot, single node group across all AZs
    # ---------------------------------------------------------------
    tools_spot = merge(local.node_group_defaults, {
      desired_size  = 1
      max_size      = 6
      min_size      = 1
      capacity_type = "SPOT"
      labels        = merge(local.tags, { "stack" = "tools" })
      taints = {
        tools = {
          key    = "stack"
          value  = "tools"
          effect = "NO_SCHEDULE"
        }
      }
    })
  }

  # Configure which log types should be enabled and how long they should be kept for
  enabled_log_types = [
    # "api",
    # "audit",
    # "authenticator",
  ]
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_in_days

  # EKS Managed Add-ons
  #
  # Only the VPC CNI, which has to exist before the nodes can join -- see the
  # comment on that local. Everything else lives in the `addons` layer, which
  # runs after `identities` and so can reference the IRSA roles it creates.
  addons = local.bootstrap_addons

  # Define tags (notice we are appending here tags required by the cluster autoscaler)
  tags = merge(local.tags,
    { "k8s.io/cluster-autoscaler/enabled" = "TRUE" },
    { "k8s.io/cluster-autoscaler/${data.terraform_remote_state.cluster-vpc.outputs.cluster_name}" = "owned" }
  )
}

resource "local_file" "metadata" {
  content  = <<EOT
type: k8s-eks-cluster
data:
  region: ${var.region}
  cluster_name: ${module.cluster.cluster_name}
  profile: ${var.profile}
EOT
  filename = "${path.module}/metadata.yaml"
}
