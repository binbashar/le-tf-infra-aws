locals {
  vpn_name = "${var.project}-${var.environment}-sso"
  
  cidr   = "172.16.0.0/16"
  split_tunnel = true
  dns_servers = [cidrhost(data.terraform_remote_state.vpc_network.outputs.vpc_cidr_block["client-vpn"], 2)]

  network_vpcs = {
    network-base = {
      region  = var.region
      profile = "${var.project}-network-devops"
      bucket  = "${var.project}-network-terraform-backend"
      key     = "network/base-network/terraform.tfstate"
    }
  }

  vpc_id = data.terraform_remote_state.network_vpcs["network-base"].outputs.vpc_id
  
  subnet_ids = [
    data.terraform_remote_state.network_vpcs["network-base"].outputs.private_subnets[0],
    data.terraform_remote_state.network_vpcs["network-base"].outputs.private_subnets[1]
  ]

  apps_devstg_vpcs = {
    apps-devstg-base = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/network/terraform.tfstate"
    }
    apps-devstg-k8s-eks = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/k8s-eks/network/terraform.tfstate"
    }
    apps-devstg-eks-demoapps = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/k8s-eks-demoapps/network/terraform.tfstate"
    }
  }

  apps_prd_vpcs = {
    apps-prd-base = {
      region  = var.region
      profile = "${var.project}-apps-prd-devops"
      bucket  = "${var.project}-apps-prd-terraform-backend"
      key     = "apps-prd/network/terraform.tfstate"
    }
    #apps-prd-k8s-eks = {
    #  region  = var.region
    # profile = "${var.project}-apps-prd-devops"
    #  bucket  = "${var.project}-apps-prd-terraform-backend"
    # key     = "apps-prd/k8s-eks/network/terraform.tfstate"
    #}
  }

  authorization_devops = [concat(
    [ for vpc in local.network_vpcs: data.terraform_remote_state[vpc].outputs.vpc_cidr_block ],
    [ for vpc in local.apps_devstg_vpcs: data.terraform_remote_state[vpc].outputs.vpc_cidr_block ],
    [ for vpc in local.apps_prd_vpcs: data.terraform_remote_state[vpc].outputs.vpc_cidr_block ]
  )]

  routes = [concat(
    [ for vpc in local.network_vpcs: data.terraform_remote_state[vpc].outputs.vpc_cidr_block ],
    [ for vpc in local.apps_devstg_vpcs: data.terraform_remote_state[vpc].outputs.vpc_cidr_block ],
    [ for vpc in local.apps_prd_vpcs: data.terraform_remote_state[vpc].outputs.vpc_cidr_block ]
  )]

  sso_group_devops = "11111111-2222-3333-4444-555555555555"

  vpn_routes = {
    for pair in setproduct(local.subnet_ids, local.routes[0]) : 
    "${pair[0]}_${replace(pair[1], "/", "_")}" => {
      target_vpc_subnet_id   = pair[0]
      destination_cidr_block = pair[1]
    }
  }
}