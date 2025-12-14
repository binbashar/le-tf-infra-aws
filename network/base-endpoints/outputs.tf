#===========================================#
# VPC Endpoints Outputs
# Organized outputs for the VPC Endpoints module configuration
#===========================================#

# Endpoints Information
output "endpoints" {
  description = "Array containing the full resource object and attributes for all endpoints created"
  value       = module.vpc_endpoints.endpoints
}

# Security Group Information
output "security_group_id" {
  description = "ID of the security group"
  value       = try(module.vpc_endpoints.security_group_id, null)
}

output "security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value       = try(module.vpc_endpoints.security_group_arn, null)
}

# Configuration Summary
output "endpoints_config_summary" {
  description = "Summary of VPC Endpoints configuration"
  value = {
    version               = var.endpoints_config.version
    region                = var.endpoints_config.region
    name                  = var.endpoints_config.metadata.name
    environment           = var.endpoints_config.metadata.environment
    vpc_id                = local.vpc_id
    endpoints_count       = length(var.endpoints_config.networking.endpoints)
    endpoints             = keys(var.endpoints_config.networking.endpoints)
    create_security_group = local.security_group_create
  }
}
