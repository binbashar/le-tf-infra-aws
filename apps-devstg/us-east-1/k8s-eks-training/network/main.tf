module "vpc" {
  source = "../../../../terraform-modules/network/"

  # PROJECT INFO
  project         = var.project
  environment     = var.environment
  vpc_name_suffix = local.name_suffix
  region          = var.region

  # the aws providers for the current and the shared account
  providers = {
    aws        = aws
    aws.shared = aws.shared
  }

  # CIDR and AZs (up to 4 AZs)
  vpc_cidr           = "10.3.0.0/16"
  availability_zones = ["a", "b"]

  # Enable NAT gateway
  vpc_enable_nat_gateway = true

  # Shared VPC to receive traffic from
  # local.shared-vpcs = shared-vpcs = {
  #                        shared-base = {
  #                          region  = var.region
  #                          profile = "${var.project}-shared-devops"
  #                          bucket  = "${var.project}-shared-terraform-backend"
  #                          key     = "shared/network/terraform.tfstate"
  #                        }
  #                      }
  #shared_vpcs = local.shared-vpcs

  # VPN Server IP overwrite
  # if create_acl_for_vpn_ip == true and vpn_private_ip is not set, the ip will be get using
  # binbash Leverage default configs
  #vpn_private_ip  = data.terraform_remote_state.tools-vpn-server.outputs.instance_private_ip

  # ROUTE53 DNS PRIVATE ZONE ASSOCIATION
  # the Route53 zone
  route53_private_zone_to_associate = data.terraform_remote_state.shared-dns.outputs.aws_internal_zone_id


  # Flow Logs
  enable_flow_logs = true

  # TAGS
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

}

