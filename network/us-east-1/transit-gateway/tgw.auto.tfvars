# Transit Gateway
# enable_tgw = false # Set this value in the `config/common.tfvars`

# TGW VPC Attahcments
enable_vpc_attach = {
  network     = false
  shared      = false
  apps-devstg = false
  apps-prd    = false
}

# Network Firewall
enable_network_firewall = false
