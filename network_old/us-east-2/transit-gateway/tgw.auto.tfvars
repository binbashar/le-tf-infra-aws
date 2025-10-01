# Transit Gateway
# enable_tgw = false # Set this value in the `config/common.tfvars`

# TGW VPC Attahcments
enable_vpc_attach = {
  network-dr     = false
  shared-dr      = false
  apps-devstg-dr = false
  apps-prd-dr    = false
}

# Network Firewall
enable_network_firewall = false
