#===========================================#
# Client VPN Outputs
# Exposes Client VPN endpoint and related resource information
#===========================================#

output "client_vpn_endpoint_id" {
  description = "The ID of the Client VPN endpoint"
  value       = aws_ec2_client_vpn_endpoint.this.id
}

output "client_vpn_endpoint_arn" {
  description = "The ARN of the Client VPN endpoint"
  value       = aws_ec2_client_vpn_endpoint.this.arn
}

output "client_vpn_endpoint_dns_name" {
  description = "The DNS name to be used by clients when establishing a VPN session"
  value       = aws_ec2_client_vpn_endpoint.this.dns_name
}

output "security_group_id" {
  description = "The ID of the security group for Client VPN"
  value       = local.security_group_create ? module.vpn_sso_sg[0].security_group_id : null
}

output "security_group_arn" {
  description = "The ARN of the security group for Client VPN"
  value       = local.security_group_create ? module.vpn_sso_sg[0].security_group_arn : null
}

output "network_associations" {
  description = "Map of network associations (subnet_id -> association_id)"
  value = {
    for k, v in aws_ec2_client_vpn_network_association.this : k => v.id
  }
}

output "authorization_rules" {
  description = "Map of authorization rules"
  value = {
    for k, v in aws_ec2_client_vpn_authorization_rule.this : k => {
      id                   = v.id
      target_network_cidr  = v.target_network_cidr
      access_group_id      = v.access_group_id
      authorize_all_groups = v.authorize_all_groups
      description          = v.description
    }
  }
}

output "routes" {
  description = "Map of VPN routes"
  value = {
    for k, v in aws_ec2_client_vpn_route.this : k => {
      id                     = v.id
      destination_cidr_block = v.destination_cidr_block
      target_vpc_subnet_id   = v.target_vpc_subnet_id
      origin                 = v.origin
      type                   = v.type
    }
  }
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group for connection logs"
  value       = local.connection_logs_enabled ? aws_cloudwatch_log_group.client_vpn[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group for connection logs"
  value       = local.connection_logs_enabled ? aws_cloudwatch_log_group.client_vpn[0].arn : null
}

output "saml_provider_arn" {
  description = "The ARN of the SAML provider (if created)"
  value       = local.saml_provider_name != null && local.saml_provider_metadata_path != null ? aws_iam_saml_provider.client_vpn[0].arn : null
}

output "client_vpn_config_summary" {
  description = "Summary of client_vpn_config for debugging"
  value = {
    name                    = local.vpn_name
    vpc_id                  = local.vpc_id
    client_cidr_block       = local.client_cidr_block
    split_tunnel            = local.split_tunnel
    transport_protocol      = local.transport_protocol
    authentication_type     = local.authentication_type
    connection_logs_enabled = local.connection_logs_enabled
  }
}
