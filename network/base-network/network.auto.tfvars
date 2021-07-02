# NAT GW
vpc_enable_nat_gateway = false

# Transit Gateway
enabled_tgw = false

# TGW VPC Attahcments
enabled_vpc_attach = {
  network     = false
  shared      = false
  apps-devstg = false
  apps-prd    = false
}
