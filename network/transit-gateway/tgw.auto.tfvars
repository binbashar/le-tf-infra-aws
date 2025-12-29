# Transit Gateway Auto Configuration
# This file is kept for backward compatibility
# New configurations should use tgw_config in environment-specific .tfvars files

# Legacy variables (for backward compatibility)
# These are mapped from tgw_config in runtime.tf
# enable_tgw = false # Set this value in the tgw_config.connection.create

# TGW VPC Attachments (legacy - use tgw_config.connection.accounts instead)
# enable_vpc_attach = {
#   network     = false
#   shared      = false
#   apps-devstg = false
#   apps-prd    = false
# }

# Network Firewall (legacy - use tgw_config.security.network_firewall.enabled instead)
# enable_network_firewall = false
