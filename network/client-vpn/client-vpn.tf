#===========================================#
# Client VPN Resources
# Maps client_vpn_config design spec to AWS Client VPN resources
# All computed values (locals) are defined in runtime.tf
#===========================================#

# SAML Provider (if configured)
resource "aws_iam_saml_provider" "client_vpn" {
  count = local.saml_provider_name != null && local.saml_provider_metadata_path != null ? 1 : 0

  name                   = local.saml_provider_name
  saml_metadata_document = file(local.saml_provider_metadata_path)
}

# Security Group for Client VPN
module "vpn_sso_sg" {
  source = "github.com/binbashar/terraform-aws-security-group?ref=v5.1.2"
  count  = local.security_group_create ? 1 : 0

  name        = local.security_group_name != null ? local.security_group_name : "${local.vpn_name}-sg"
  description = local.security_group_description != null ? local.security_group_description : "Security group for Client VPN endpoint"
  vpc_id      = local.vpc_id

  egress_with_cidr_blocks = try(local.security_group_rules.egress, [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ])

  tags = merge(
    local.tags,
    local.security_group_tags
  )
}

# CloudWatch Log Group for Connection Logs
resource "aws_cloudwatch_log_group" "client_vpn" {
  count = local.connection_logs_enabled ? 1 : 0

  name              = local.connection_logs_log_group != null ? local.connection_logs_log_group : "${local.vpn_name}-logs"
  retention_in_days = local.connection_logs_retention_in_days
  kms_key_id        = local.connection_logs_kms_key_id

  tags = local.tags
}

# Client VPN Endpoint
resource "aws_ec2_client_vpn_endpoint" "this" {
  description            = local.vpn_name
  vpc_id                 = local.vpc_id
  server_certificate_arn = local.server_certificate_arn
  client_cidr_block      = local.client_cidr_block
  split_tunnel           = local.split_tunnel
  dns_servers            = length(local.dns_servers) > 0 ? local.dns_servers : null
  transport_protocol     = local.transport_protocol
  security_group_ids     = local.security_group_create ? [module.vpn_sso_sg[0].security_group_id] : []

  authentication_options {
    type                       = local.authentication_type
    saml_provider_arn          = local.authentication_type == "federated-authentication" ? (local.saml_provider_arn != null ? local.saml_provider_arn : aws_iam_saml_provider.client_vpn[0].arn) : null
    root_certificate_chain_arn = local.authentication_type == "certificate-authentication" ? local.root_certificate_chain_arn : null
  }

  connection_log_options {
    enabled              = local.connection_logs_enabled
    cloudwatch_log_group = local.connection_logs_enabled && local.connection_logs_log_group != null ? local.connection_logs_log_group : (local.connection_logs_enabled ? aws_cloudwatch_log_group.client_vpn[0].name : null)
  }

  tags = local.tags
}

# Network Associations
resource "aws_ec2_client_vpn_network_association" "this" {
  for_each = toset(local.subnet_ids)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = each.key
}

# Authorization Rules
resource "aws_ec2_client_vpn_authorization_rule" "this" {
  for_each = {
    for rule in local.authorization_rules : "${rule.target_network_cidr}_${try(rule.access_group_id, "all")}" => rule
  }

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = each.value.target_network_cidr
  access_group_id        = try(each.value.access_group_id, null)
  authorize_all_groups   = try(each.value.authorize_all_groups, false)
  description            = try(each.value.description, null)
}

# VPN Routes
resource "aws_ec2_client_vpn_route" "this" {
  for_each = local.vpn_routes

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  destination_cidr_block = each.value.destination_cidr_block
  target_vpc_subnet_id   = each.value.target_vpc_subnet_id
}
