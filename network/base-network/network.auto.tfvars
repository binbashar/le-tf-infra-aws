# NAT GW
vpc_enable_nat_gateway = false

# Transit Gateway
enable_tgw = false

# TGW VPC Attahcments
enable_vpc_attach = {
  network     = false
  shared      = false
  apps-devstg = false
  apps-prd    = false
}

# Network Firewall
enable_network_firewall = false
