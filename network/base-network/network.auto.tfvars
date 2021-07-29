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

# VPN Gateways
enable_vpn_gateway = false
customer_gateways = {
  cgw1 = {
    bgp_asn    = 65220
    ip_address = "172.83.124.10"
    tunnel1 = {
      inside_cidr   = "169.254.10.0/30"
      preshared_key = "pr3shr3_k3y1"
    }
    tunnel2 = {
      inside_cidr   = "169.254.10.4/30"
      preshared_key = "pr3shr3_k3y2"
    }
    static_routes = ["10.10.0.0/20", "10.30.0.0/20"]
  },
  cgw2 = {
    bgp_asn    = 65220
    ip_address = "172.83.124.11"
    tunnel1 = {
      inside_cidr   = "169.254.10.8/30"
      preshared_key = "pr3shr3_k3y3"
    }
    tunnel2 = {
      inside_cidr   = "169.254.10.12/30"
      preshared_key = "pr3shr3_k3y4"
    }
    #static_routes = ["10.40.0.0/20", "10.50.0.0/20"]
  }
}
