#===========================================#
# Client VPN Configuration Locals
# Computed values derived from client_vpn_config design spec
#===========================================#
locals {
  # VPN endpoint name
  vpn_name = var.client_vpn_config.metadata.name

  # Connection values
  vpc_id     = try(var.client_vpn_config.connection.vpc_id, null)
  subnet_ids = var.client_vpn_config.connection.subnet_ids

  # Networking values
  client_cidr_block  = var.client_vpn_config.networking.client_cidr_block
  split_tunnel       = try(var.client_vpn_config.networking.split_tunnel, true)
  dns_servers        = try(var.client_vpn_config.networking.dns_servers, [])
  transport_protocol = try(var.client_vpn_config.networking.transport_protocol, "udp")

  # Routes transformation
  # If routes are explicitly defined, use them; otherwise generate from subnet_ids and authorization_rules
  vpn_routes = length(var.client_vpn_config.networking.routes) > 0 ? {
    for route in var.client_vpn_config.networking.routes :
    "${route.target_subnet_id}_${replace(route.destination_cidr_block, "/", "_")}" => {
      target_vpc_subnet_id   = route.target_subnet_id
      destination_cidr_block = route.destination_cidr_block
    }
  } : {}

  # Security values
  server_certificate_arn     = var.client_vpn_config.security.server_certificate_arn
  authentication_type        = var.client_vpn_config.security.authentication.type
  saml_provider_arn          = try(var.client_vpn_config.security.authentication.saml_provider_arn, null)
  root_certificate_chain_arn = try(var.client_vpn_config.security.authentication.root_certificate_chain_arn, null)

  # Security group configuration
  security_group_create      = try(var.client_vpn_config.security.security_group.create, true)
  security_group_name        = try(var.client_vpn_config.security.security_group.name, null)
  security_group_description = try(var.client_vpn_config.security.security_group.description, null)
  security_group_rules       = try(var.client_vpn_config.security.security_group.rules, {})
  security_group_tags        = try(var.client_vpn_config.security.security_group.tags, {})

  # Authorization rules
  authorization_rules = try(var.client_vpn_config.security.authorization_rules, [])

  # Logging values
  connection_logs_enabled           = try(var.client_vpn_config.logging.connection_logs.enabled, true)
  connection_logs_log_group         = try(var.client_vpn_config.logging.connection_logs.cloudwatch_log_group, null)
  connection_logs_retention_in_days = try(var.client_vpn_config.logging.connection_logs.retention_in_days, 60)
  connection_logs_kms_key_id        = try(var.client_vpn_config.logging.connection_logs.kms_key_id, null)

  # Compliance values
  saml_provider_name          = try(var.client_vpn_config.compliance.saml_provider.name, null)
  saml_provider_metadata_path = try(var.client_vpn_config.compliance.saml_provider.saml_metadata_path, null)
  sso_groups                  = try(var.client_vpn_config.compliance.sso_groups, {})

  # High availability
  multi_az = try(var.client_vpn_config.high_availability.multi_az, true)

  # Tags
  tags = var.client_vpn_config.metadata.tags

  # Remote state data sources (for backward compatibility)
  # These are only used if client_vpn_config.connection.vpc_id is null
  # and we need to look up VPC information from remote state
  # NOTE: These should be removed when fully migrating to client_vpn_config
  remote_state_network_vpcs     = {}
  remote_state_apps_devstg_vpcs = {}
  remote_state_apps_prd_vpcs    = {}
}

