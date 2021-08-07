# NAT GW
vpc_enable_nat_gateway = false
vpc_single_nat_gateway = true

# VPN Gateways
vpc_enable_vpn_gateway = false
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
    vpn_connection_static_routes_only = true
    static_routes                     = ["10.10.0.0/20", "10.30.0.0/20"]
    local_ipv4_network_cidr           = "10.0.0.0/16"
    #remote_ipv4_network_cidr          = "0.0.0.0/0"
  },
  cgw2 = {
    bgp_asn    = 65220
    ip_address = "172.83.124.11"
    tunnel1 = {
      inside_cidr   = "169.254.10.8/30"
      preshared_key = "pr3shr3_k3y3"
      # Other parameters (https://github.com/binbashar/terraform-aws-vpn-gateway#inputs)
      #dpd_timeout_action           = ""
      #dpd_timeout_seconds          = 30
      #ike_versions                 = ["ikev1", "ikev2"]
      #phase1_dh_group_numbers      = [2, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
      #phase1_encryption_algorithms = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
      #phase1_lifetime_seconds      = 28800
      #phase2_dh_group_numbers      = [2, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
      #phase2_encryption_algorithms = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
      #phase2_lifetime_seconds      = 3600
      #rekey_fuzz_percentage        = 100
      #rekey_margin_time_seconds    = 540
      #replay_window_size           = 1024
      #startup_action               = "add"
    }
    tunnel2 = {
      inside_cidr   = "169.254.10.12/30"
      preshared_key = "pr3shr3_k3y4"
      # Other parameters (https://github.com/binbashar/terraform-aws-vpn-gateway#inputs)
      #dpd_timeout_action           = ""
      #dpd_timeout_seconds          = 30
      #ike_versions                 = ["ikev1", "ikev2"]
      #phase1_dh_group_numbers      = [2, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
      #phase1_encryption_algorithms = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
      #phase1_lifetime_seconds      = 28800
      #phase2_dh_group_numbers      = [2, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
      #phase2_encryption_algorithms = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
      #phase2_lifetime_seconds      = 3600
      #rekey_fuzz_percentage        = 100
      #rekey_margin_time_seconds    = 540
      #replay_window_size           = 1024
      #startup_action               = "add"
    }
    #static_routes = ["10.40.0.0/20", "10.50.0.0/20"]
  }
}
