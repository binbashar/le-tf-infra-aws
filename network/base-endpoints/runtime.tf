#===========================================#
# VPC Endpoints Configuration Locals
# Computed values derived from endpoints_config design spec
#===========================================#
locals {
  # Default values
  default_create     = try(var.endpoints_config.defaults.create, true)
  default_subnet_ids = try(var.endpoints_config.defaults.subnet_ids, [])
  default_tags = merge(
    try(var.endpoints_config.metadata.tags, {}),
    try(var.endpoints_config.defaults.tags, {})
  )
  default_timeouts = try(var.endpoints_config.defaults.timeouts, {
    create = "10m"
    update = "10m"
    delete = "10m"
  })

  # Security configuration
  security_group_create      = try(var.endpoints_config.security.security_group.create, false)
  security_group_name        = try(var.endpoints_config.security.security_group.name, null)
  security_group_name_prefix = try(var.endpoints_config.security.security_group.name_prefix, null)
  security_group_description = try(var.endpoints_config.security.security_group.description, null)
  security_group_rules       = try(var.endpoints_config.security.security_group.rules, {})
  security_group_tags        = try(var.endpoints_config.security.security_group.tags, {})
  default_security_group_ids = try(var.endpoints_config.security.default_security_group_ids, [])

  # VPC ID
  vpc_id = try(var.endpoints_config.connection.vpc_id, null)
}
