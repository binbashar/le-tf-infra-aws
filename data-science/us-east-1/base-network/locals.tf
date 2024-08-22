locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  # Network Local Vars
  # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
  # Important
  # Docker runs in the 172.17.0.0/16 CIDR range in Amazon EKS clusters. We recommend that your cluster's VPC subnets do
  # not overlap this range. Otherwise, you will receive the following error:
  # Error: : error upgrading connection: error dialing backend: dial tcp 172.17.nn.nn:10250: getsockopt: no route to host
  vpc_name       = "${var.project}-${var.environment}-vpc"
  vpc_cidr_block = "172.19.0.0/20" #https://www.davidc.net/sites/default/subnets/subnets.html?network=172.19.0.0&mask=20&division=15.7231
  azs = [
    "${var.region}a",
    "${var.region}b",
  ]

  private_subnets_cidr = ["172.19.0.0/21"]
  private_subnets = [
    "172.19.0.0/23",
    "172.19.2.0/23",
  ]

  public_subnets_cidr = ["172.19.8.0/21"]
  public_subnets = [
    "172.19.8.0/23",
    "172.19.10.0/23",
    #    "172.18.44.0/23",
  ]

  #
  # K8s Kops Requisites
  #
  # We'll use a shorter environment name in order to keep things simple
  #short_environment = replace(var.environment, "apps-", "")

  # The name of the K8s Kops Dev cluster
  #   base_domain_name = "binbash.aws"
  #   k8s_cluster_name = "cluster-kops-1.k8s.${local.short_environment}.${local.base_domain_name}"

  # We need these so that k8s aws cloud provider recognizes our private subnets
  # and associates them to any load balancer that is created
  #   private_subnet_tags = {
  #     "kubernetes.io/cluster/${local.k8s_cluster_name}" : 1
  #     "kubernetes.io/role/internal-elb" : 1
  #   }
  #   public_subnet_tags = {
  #     "kubernetes.io/cluster/${local.k8s_cluster_name}" : 1
  #     "kubernetes.io/role/elb" : 1
  #   }
}

locals {
  # private inbounds
  #   private_inbound = flatten([
  #     for index, state in local.datasources-vpcs : [
  #       for k, v in state.outputs.private_subnets_cidr :
  #       {
  #         rule_number = 10 * (index(keys(local.datasources-vpcs), index) + 1) + 100 * k
  #         rule_action = "allow"
  #         from_port   = 0
  #         to_port     = 65535
  #         protocol    = "all"
  #         cidr_block  = state.outputs.private_subnets_cidr[k]
  #       }
  #     ]
  #   ])
  private_inbound = [
    # {
    #   rule_number = 100 # shared pritunl vpn server
    #   rule_action = "allow"
    #   from_port   = 0
    #   to_port     = 65535
    #   protocol    = "all"
    #   cidr_block  = "${data.terraform_remote_state.tools-vpn-server.outputs.instance_private_ip}/32"
    # },
  ]

  network_acls = {
    #
    # Allow / Deny VPC private subnets inbound default traffic
    #
    default_inbound = [
      {
        rule_number = 800 # own private subnet cidr
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "all"
        cidr_block  = local.private_subnets_cidr[0]
      },
    #   {
    #     rule_number = 900 # shared pritunl vpn server
    #     rule_action = "allow"
    #     from_port   = 0
    #     to_port     = 65535
    #     protocol    = "all"
    #     cidr_block  = "${data.terraform_remote_state.tools-vpn-server.outputs.instance_private_ip}/32"
    #   },
      {
        rule_number = 910 # NTP traffic
        rule_action = "allow"
        from_port   = 123
        to_port     = 123
        protocol    = "udp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 920 # Fltering known TCP ports (0-1024)
        rule_action = "allow"
        from_port   = 1024
        to_port     = 65525
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 930 # Fltering known UDP ports (0-1024)
        rule_action = "allow"
        from_port   = 1024
        to_port     = 65525
        protocol    = "udp"
        cidr_block  = "0.0.0.0/0"
      },
    ]

    #
    # Allow VPC private subnets inbound traffic
    #
    private_inbound = local.private_inbound
  }
}
